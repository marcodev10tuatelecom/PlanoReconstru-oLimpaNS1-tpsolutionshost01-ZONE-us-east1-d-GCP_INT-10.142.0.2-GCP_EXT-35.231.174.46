#!/usr/bin/env bash
# ============================================================
# TPS-NS1-CLEANROOM-MASTER-FOUNDATION v2.1.0
# NS1 clean-room state-driven foundation runner
# Canonical naming: no -main; media domain: studiosatweb.com.br
# Scope: R00-R07 local foundation only
# ============================================================
set -Eeuo pipefail
IFS=$'\n\t'
umask 027
export LC_ALL=C LANG=C TZ=UTC

PROGRAM='TPS-NS1-CLEANROOM-MASTER-FOUNDATION'
VERSION='2.1.0'
EXPECTED_HOST='ns1.tpsolutions.com.br'
EXPECTED_GCP_INSTANCE='tpsolutionshost01'
EXPECTED_GCP_PRIVATE='10.142.0.2'
EXPECTED_GCP_PUBLIC='35.231.174.46'
COMPANY_DOMAIN='tpsolutions.com.br'
MEDIA_DOMAIN='studiosatweb.com.br'
MTX_BIN='/opt/tpsmedia/mediamtx/current/mediamtx'
MTX_CFG='/etc/tpsmedia/mediamtx/mediamtx.yml'
MTX_UNIT='tps-mediamtx.service'
REPO='/srv/tpsmedia/repository'
CHANNELS=(radioprincipal radiopop radiorock radioclassicas radiocountry tvkids tvteens tvviva tvmaisjovem)
DEPRECATED_CHANNELS=(radio-main radio-pop radio-rock radio-classicas radio-country tvkids-main tvteens-main tvviva-main tvmaisjovem-main radiotv-main tv-main tv2-main tv-crista-main tv-jovem-main)
RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${PROGRAM}-${VERSION}-${RUN_TS}"
WORK="/var/tmp/${RUN_ID}"
BACKUP="/root/TPS-NS1-CLEANROOM-BACKUP-${RUN_TS}"
REPORT="/root/${RUN_ID}.report.txt"
MUTATED_MTX=0
MTX_CFG_BACKED_UP=0
MTX_WAS_ACTIVE=0
MTX_PID_BEFORE='0'
MTX_RESTARTS_BEFORE='0'
LAB_PID=''
LAB_PUBLISHER_PID=''
BIND_UNIT=''

log(){ printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$REPORT"; }
section(){ printf '\n============================================================\n%s\n============================================================\n' "$*" | tee -a "$REPORT"; }
fatal(){ log "FATAL=$*"; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

cleanup_lab(){
  if [[ -n "${LAB_PUBLISHER_PID:-}" ]] && kill -0 "$LAB_PUBLISHER_PID" 2>/dev/null; then
    kill -TERM "$LAB_PUBLISHER_PID" 2>/dev/null || true
    wait "$LAB_PUBLISHER_PID" 2>/dev/null || true
  fi
  LAB_PUBLISHER_PID=''
  if [[ -n "${LAB_PID:-}" ]] && kill -0 "$LAB_PID" 2>/dev/null; then
    kill -TERM "$LAB_PID" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      kill -0 "$LAB_PID" 2>/dev/null || break
      sleep 1
    done
    kill -KILL "$LAB_PID" 2>/dev/null || true
    wait "$LAB_PID" 2>/dev/null || true
  fi
  LAB_PID=''
}

rollback(){
  local rc=$?
  cleanup_lab
  if (( MUTATED_MTX == 1 )); then
    log 'ROLLBACK_MEDIAMTX=START'
    if (( MTX_CFG_BACKED_UP == 1 )) && [[ -f "$BACKUP/mediamtx.yml.before" ]]; then
      install -o root -g tpsmedia -m 0640 "$BACKUP/mediamtx.yml.before" "$MTX_CFG" || true
      if (( MTX_WAS_ACTIVE == 1 )); then
        sleep 4
      fi
    fi
    if (( MTX_WAS_ACTIVE == 0 )); then
      systemctl stop "$MTX_UNIT" >/dev/null 2>&1 || true
    fi
    log 'ROLLBACK_MEDIAMTX=COMPLETE'
  fi
  log "RESULT=FAIL RC=$rc"
  exit "$rc"
}
trap rollback ERR INT TERM

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'FATAL=RUN_AS_ROOT_REQUIRED' >&2; exit 1; }
mkdir -p "$WORK"
touch "$REPORT"
chmod 0600 "$REPORT"

section "${PROGRAM} v${VERSION}"
log "RUN_ID=$RUN_ID"
log 'MODE=STATE_DRIVEN_ANALYZE_TEST_EXECUTE_VALIDATE'
log 'VM_RECREATE=FORBIDDEN'
log 'CORE_RESTART_NORMAL_PATH=FORBIDDEN'
log "COMPANY_DOMAIN=$COMPANY_DOMAIN"
log "MEDIA_DOMAIN=$MEDIA_DOMAIN"
log "CANONICAL_CHANNELS=${CHANNELS[*]}"

section 'R00 — SELF VALIDATION + ADMISSION'
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
bash -n "$SCRIPT_PATH" || fatal 'SELF_BASH_N_FAIL'
have shellcheck || fatal 'SHELLCHECK_REQUIRED'
shellcheck -S warning "$SCRIPT_PATH" || fatal 'SELF_SHELLCHECK_FAIL'
log 'SELF_SHELLCHECK=PASS'

for c in curl python3 systemctl install sha256sum ffmpeg ffprobe runuser dig nginx named-checkconf find pgrep; do
  have "$c" || fatal "MISSING_COMMAND:$c"
done
python3 - <<'PY' >/dev/null || fatal 'PYYAML_MISSING'
import yaml
PY
getent group www-data >/dev/null || fatal 'WWW_DATA_GROUP_MISSING'

HOST_FQDN="$(hostname -f 2>/dev/null || hostname)"
[[ "$HOST_FQDN" == "$EXPECTED_HOST" ]] || fatal "HOST_MISMATCH:$HOST_FQDN"
BASE='http://metadata.google.internal/computeMetadata/v1'
HDR='Metadata-Flavor: Google'
GCP_INSTANCE="$(curl -fsS --connect-timeout 1 --max-time 3 -H "$HDR" "$BASE/instance/name")"
GCP_PRIVATE="$(curl -fsS --connect-timeout 1 --max-time 3 -H "$HDR" "$BASE/instance/network-interfaces/0/ip")"
GCP_PUBLIC="$(curl -fsS --connect-timeout 1 --max-time 3 -H "$HDR" "$BASE/instance/network-interfaces/0/access-configs/0/external-ip")"
[[ "$GCP_INSTANCE" == "$EXPECTED_GCP_INSTANCE" ]] || fatal "GCP_INSTANCE_MISMATCH:$GCP_INSTANCE"
[[ "$GCP_PRIVATE" == "$EXPECTED_GCP_PRIVATE" ]] || fatal "GCP_PRIVATE_MISMATCH:$GCP_PRIVATE"
[[ "$GCP_PUBLIC" == "$EXPECTED_GCP_PUBLIC" ]] || fatal "GCP_PUBLIC_MISMATCH:$GCP_PUBLIC"
log "IDENTITY=PASS HOST=$HOST_FQDN GCP_INSTANCE=$GCP_INSTANCE PRIVATE=$GCP_PRIVATE PUBLIC=$GCP_PUBLIC"

mapfile -t LEGACY_DIRS < <(find /srv -maxdepth 1 -type d -name 'tpsmedia-legacy-*' -print | sort)
((${#LEGACY_DIRS[@]} > 0)) || fatal 'NO_LEGACY_ISOLATION_FOUND'
log "LEGACY_ISOLATIONS=${#LEGACY_DIRS[@]}"

FFCOUNT="$(pgrep -x ffmpeg 2>/dev/null | wc -l || true)"
[[ "$FFCOUNT" == '0' ]] || fatal "FFMPEG_STILL_ACTIVE:$FFCOUNT"
systemctl is-active --quiet nginx || fatal 'NGINX_NOT_ACTIVE'
if systemctl is-active --quiet bind9; then
  BIND_UNIT='bind9.service'
elif systemctl is-active --quiet named; then
  BIND_UNIT='named.service'
else
  fatal 'BIND_NOT_ACTIVE'
fi
nginx -t >/dev/null 2>&1 || fatal 'NGINX_CONFIG_INVALID'
named-checkconf >/dev/null 2>&1 || fatal 'BIND_CONFIG_INVALID'
[[ -x "$MTX_BIN" ]] || fatal "MEDIAMTX_BINARY_MISSING:$MTX_BIN"
systemctl cat "$MTX_UNIT" >/dev/null 2>&1 || fatal "MEDIAMTX_UNIT_MISSING:$MTX_UNIT"
id tpsmedia >/dev/null 2>&1 || fatal 'TPSMEDIA_ACCOUNT_MISSING'

if systemctl is-active --quiet "$MTX_UNIT"; then MTX_WAS_ACTIVE=1; fi
MTX_PID_BEFORE="$(systemctl show "$MTX_UNIT" -p MainPID --value 2>/dev/null || echo 0)"
MTX_RESTARTS_BEFORE="$(systemctl show "$MTX_UNIT" -p NRestarts --value 2>/dev/null || echo 0)"
log "CORE_BEFORE NGINX=active BIND=$BIND_UNIT MEDIAMTX_ACTIVE=$MTX_WAS_ACTIVE MEDIAMTX_PID=$MTX_PID_BEFORE NRESTARTS=$MTX_RESTARTS_BEFORE FFMPEG=$FFCOUNT"

section 'R01 — FORENSIC BACKUP + NAME COLLISION GATE'
mkdir -p "$BACKUP/systemd" "$BACKUP/retired-empty-channel-dirs"
chmod 0700 "$BACKUP"
for p in /etc/tpsmedia /etc/nginx /etc/bind; do
  [[ -e "$p" ]] && cp -a "$p" "$BACKUP/"
done
find /etc/systemd/system -maxdepth 2 -type f -name 'tps-*' -exec cp -a --parents {} "$BACKUP/systemd/" \; 2>/dev/null || true
find /srv -maxdepth 1 -type d -name 'tpsmedia-legacy-*' -printf '%p\n' > "$BACKUP/legacy-paths.txt"
find /srv/tpsmedia -xdev -maxdepth 5 -printf '%M %u:%g %s %p\n' 2>/dev/null > "$BACKUP/tpsmedia-tree-before.txt" || true
sha256sum "$SCRIPT_PATH" > "$BACKUP/runner.sha256"
if [[ -f "$MTX_CFG" ]]; then
  cp -a "$MTX_CFG" "$BACKUP/mediamtx.yml.before"
  MTX_CFG_BACKED_UP=1
fi

if [[ -d "$REPO/channels" ]]; then
  for old in "${DEPRECATED_CHANNELS[@]}"; do
    olddir="$REPO/channels/$old"
    [[ -d "$olddir" ]] || continue
    mv "$olddir" "$BACKUP/retired-empty-channel-dirs/$old"
    log "RETIRED_DEPRECATED_CHANNEL_PRESERVED=$old"
  done
fi
log "BACKUP=PASS PATH=$BACKUP"

section 'R02 — BUILD + STATIC VALIDATE CLEAN MEDIAMTX CANDIDATE'
CAND="$WORK/mediamtx.clean.yml"
cat > "$CAND" <<'YAML'
logLevel: info
logDestinations: [stdout]
logStructured: false

authMethod: internal
authInternalUsers:
  - user: any
    pass:
    ips: ["127.0.0.1", "::1"]
    permissions:
      - action: publish
        path: "~^(radioprincipal|radiopop|radiorock|radioclassicas|radiocountry|tvkids|tvteens|tvviva|tvmaisjovem)$"
      - action: read
        path: "~^(radioprincipal|radiopop|radiorock|radioclassicas|radiocountry|tvkids|tvteens|tvviva|tvmaisjovem)$"
      - action: api
      - action: metrics
  - user: any
    pass:
    ips: []
    permissions:
      - action: read
        path: "~^(radioprincipal|radiopop|radiorock|radioclassicas|radiocountry|tvkids|tvteens|tvviva|tvmaisjovem)$"

api: true
apiAddress: 127.0.0.1:9997
metrics: true
metricsAddress: 127.0.0.1:9998
pprof: false
playback: false
rtsp: false
rtmp: true
rtmpAddress: :1935
hls: true
hlsAddress: 127.0.0.1:8888
webrtc: false
srt: false

pathDefaults:
  source: publisher
  overridePublisher: false
  record: false

paths:
  radioprincipal: {}
  radiopop: {}
  radiorock: {}
  radioclassicas: {}
  radiocountry: {}
  tvkids: {}
  tvteens: {}
  tvviva: {}
  tvmaisjovem: {}
YAML
python3 - "$CAND" <<'PY'
import sys,yaml
p=sys.argv[1]
d=yaml.safe_load(open(p,encoding='utf-8'))
exp=['radioprincipal','radiopop','radiorock','radioclassicas','radiocountry','tvkids','tvteens','tvviva','tvmaisjovem']
assert list(d.get('paths',{}).keys()) == exp, (list(d.get('paths',{})), exp)
assert d['pathDefaults']['overridePublisher'] is False
assert d['api'] is True and d['apiAddress']=='127.0.0.1:9997'
assert d['metrics'] is True and d['metricsAddress']=='127.0.0.1:9998'
assert d['hls'] is True and d['hlsAddress']=='127.0.0.1:8888'
assert d['rtmp'] is True and d['rtmpAddress']==':1935'
assert d['rtsp'] is False and d['webrtc'] is False and d['srt'] is False
PY
log "MEDIAMTX_CANDIDATE=PASS SHA256=$(sha256sum "$CAND" | awk '{print $1}')"

section 'R03 — REAL MEDIAMTX LAB + SYNTHETIC RTMP/HLS'
LABLOG="$WORK/mediamtx-lab.log"
runuser -u tpsmedia -- env \
  MTX_APIADDRESS=127.0.0.1:19997 \
  MTX_METRICSADDRESS=127.0.0.1:19998 \
  MTX_RTMPADDRESS=127.0.0.1:11935 \
  MTX_HLSADDRESS=127.0.0.1:18888 \
  "$MTX_BIN" "$CAND" >"$LABLOG" 2>&1 &
LAB_PID=$!
for _ in $(seq 1 30); do
  curl -fsS --max-time 1 http://127.0.0.1:19997/v3/paths/list >/dev/null 2>&1 && break
  sleep 0.5
done
curl -fsS --max-time 2 http://127.0.0.1:19997/v3/paths/list >/dev/null || { cat "$LABLOG" >&2; fatal 'MEDIAMTX_LAB_API_FAIL'; }
curl -fsS --max-time 2 http://127.0.0.1:19998/metrics >/dev/null || { cat "$LABLOG" >&2; fatal 'MEDIAMTX_LAB_METRICS_FAIL'; }

ffmpeg -hide_banner -loglevel error -re -f lavfi -i 'sine=frequency=997:sample_rate=48000' \
  -t 12 -c:a aac -b:a 96k -ar 48000 -ac 2 -f flv \
  rtmp://127.0.0.1:11935/radiopop >"$WORK/lab-ffmpeg.log" 2>&1 &
LAB_PUBLISHER_PID=$!

READY=0
for _ in $(seq 1 30); do
  if curl -fsS --max-time 1 http://127.0.0.1:19997/v3/paths/list | python3 -c '
import json,sys
d=json.load(sys.stdin)
raise SystemExit(0 if any(x.get("name")=="radiopop" and x.get("ready") is True for x in d.get("items",[])) else 1)
' 2>/dev/null; then READY=1; break; fi
  sleep 0.5
done
(( READY == 1 )) || { cat "$WORK/lab-ffmpeg.log" >&2 || true; cat "$LABLOG" >&2 || true; fatal 'MEDIAMTX_LAB_PATH_NOT_READY'; }

HLS=0
for _ in $(seq 1 40); do
  if curl -fsS --max-time 1 http://127.0.0.1:18888/radiopop/index.m3u8 >"$WORK/lab.m3u8" 2>/dev/null && grep -q '^#EXTM3U' "$WORK/lab.m3u8"; then
    HLS=1
    break
  fi
  sleep 0.5
done
(( HLS == 1 )) || { cat "$LABLOG" >&2 || true; fatal 'MEDIAMTX_LAB_HLS_FAIL'; }

wait "$LAB_PUBLISHER_PID" || fatal 'MEDIAMTX_LAB_PUBLISHER_FAIL'
LAB_PUBLISHER_PID=''
cleanup_lab
log 'MEDIAMTX_LAB=PASS PATH=radiopop SYNTHETIC_PUBLISH=PASS HLS=PASS'

section 'R04 — SERVICE IDENTITIES + CANONICAL CAS REPOSITORY'
getent group tps-media >/dev/null || groupadd --system tps-media
for acct in tps-playout tps-monitor; do
  if ! id "$acct" >/dev/null 2>&1; then
    useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin --gid tps-media "$acct"
  fi
  [[ "$(getent passwd "$acct" | cut -d: -f7)" == '/usr/sbin/nologin' ]] || fatal "SERVICE_LOGIN_SHELL_INVALID:$acct"
done
usermod -a -G tps-media tpsmedia

install -d -o root -g root -m 0755 /srv/tpsmedia
install -d -o tps-playout -g tps-media -m 0750 "$REPO"
install -d -o root -g tps-media -m 0750 /srv/tpsmedia/bin
install -d -o root -g tps-media -m 0770 /srv/tpsmedia/logs
install -d -o root -g www-data -m 0755 /srv/tpsmedia/www
install -d -o tps-playout -g tps-media -m 0750 "$REPO/objects/sha256" "$REPO/channels" "$REPO/catalog"

for ch in "${CHANNELS[@]}"; do
  base="$REPO/channels/$ch"
  install -d -o tps-playout -g tps-media -m 0750 \
    "$base" "$base/refs" "$base/playlists" "$base/state" "$base/incoming" "$base/quarantine" "$base/logs" "$base/ready"
done

python3 - "$REPO/catalog/channels.json" <<'PY'
import json,os,sys,tempfile
p=sys.argv[1]
rows=[
 ('radioprincipal','radio','radio.studiosatweb.com.br'),
 ('radiopop','radio','radiopop.studiosatweb.com.br'),
 ('radiorock','radio','radiorock.studiosatweb.com.br'),
 ('radioclassicas','radio','radioclassicas.studiosatweb.com.br'),
 ('radiocountry','radio','radiocountry.studiosatweb.com.br'),
 ('tvkids','tv','tvkids.studiosatweb.com.br'),
 ('tvteens','tv','tvteens.studiosatweb.com.br'),
 ('tvviva','tv','tvviva.studiosatweb.com.br'),
 ('tvmaisjovem','tv','tvmaisjovem.studiosatweb.com.br')]
d={
 'schema':2,
 'authority':'TPS-NS1-CLEANROOM-V2',
 'company_domain':'tpsolutions.com.br',
 'media_domain':'studiosatweb.com.br',
 'channels':[{'channel_id':c,'media_type':t,'public_fqdn':fqdn} for c,t,fqdn in rows]
}
fd,tmp=tempfile.mkstemp(dir=os.path.dirname(p),prefix='.channels.',text=True)
with os.fdopen(fd,'w',encoding='utf-8') as f:
  json.dump(d,f,ensure_ascii=False,indent=2)
  f.write('\n')
  f.flush()
  os.fsync(f.fileno())
os.replace(tmp,p)
PY
chown tps-playout:tps-media "$REPO/catalog/channels.json"
chmod 0640 "$REPO/catalog/channels.json"

mapfile -t ACTUAL_CHANNELS < <(find "$REPO/channels" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
EXPECTED_SORTED="$(printf '%s\n' "${CHANNELS[@]}" | sort)"
ACTUAL_SORTED="$(printf '%s\n' "${ACTUAL_CHANNELS[@]}" | sort)"
[[ "$ACTUAL_SORTED" == "$EXPECTED_SORTED" ]] || fatal "CHANNEL_DIRECTORY_SET_MISMATCH:$(printf '%s,' "${ACTUAL_CHANNELS[@]}")"
log 'REPOSITORY=PASS CAS=ENABLED CHANNELS=9 NAMING=FINAL_NO_MAIN'

section 'R05 — APPLY CLEAN MEDIAMTX + START/HOT-RELOAD'
mkdir -p "$(dirname "$MTX_CFG")"
install -o root -g tpsmedia -m 0640 "$CAND" "$MTX_CFG"
MUTATED_MTX=1
if (( MTX_WAS_ACTIVE == 1 )); then
  sleep 4
  systemctl is-active --quiet "$MTX_UNIT" || fatal 'MEDIAMTX_DIED_AFTER_HOT_RELOAD'
  PID_NOW="$(systemctl show "$MTX_UNIT" -p MainPID --value)"
  [[ "$PID_NOW" == "$MTX_PID_BEFORE" ]] || fatal "MEDIAMTX_UNEXPECTED_PID_CHANGE:$MTX_PID_BEFORE:$PID_NOW"
  log 'MEDIAMTX_APPLY=HOT_RELOAD PID_UNCHANGED=YES'
else
  systemctl start "$MTX_UNIT"
  for _ in $(seq 1 20); do
    systemctl is-active --quiet "$MTX_UNIT" && break
    sleep 1
  done
  systemctl is-active --quiet "$MTX_UNIT" || { journalctl -u "$MTX_UNIT" -n 100 --no-pager >&2 || true; fatal 'MEDIAMTX_START_FAIL'; }
  log 'MEDIAMTX_APPLY=START_FROM_INACTIVE'
fi
curl -fsS --max-time 3 http://127.0.0.1:9997/v3/paths/list >/dev/null || fatal 'MEDIAMTX_PROD_API_FAIL'
curl -fsS --max-time 3 http://127.0.0.1:9998/metrics >/dev/null || fatal 'MEDIAMTX_PROD_METRICS_FAIL'
python3 - "$MTX_CFG" <<'PY'
import sys,yaml
exp={'radioprincipal','radiopop','radiorock','radioclassicas','radiocountry','tvkids','tvteens','tvviva','tvmaisjovem'}
d=yaml.safe_load(open(sys.argv[1],encoding='utf-8'))
assert set(d.get('paths',{})) == exp
assert 'all_others' not in d.get('paths',{})
PY
log 'MEDIAMTX_PRODUCTION=PASS CONFIGURED_PATHS=9 ACTIVE_RUNTIME_PATHS_EXPECTED=0_UNTIL_PUBLISHERS'

section 'R06 — CORE INVARIANTS + FINAL NAMING CONTRACT'
systemctl is-active --quiet nginx || fatal 'NGINX_CHANGED_TO_INACTIVE'
systemctl is-active --quiet "$BIND_UNIT" || fatal 'BIND_CHANGED_TO_INACTIVE'
systemctl is-active --quiet "$MTX_UNIT" || fatal 'MEDIAMTX_NOT_ACTIVE_AFTER_APPLY'
nginx -t >/dev/null 2>&1 || fatal 'NGINX_CONFIG_BROKEN_AFTER'
named-checkconf >/dev/null 2>&1 || fatal 'BIND_CONFIG_BROKEN_AFTER'
FFCOUNT_AFTER="$(pgrep -x ffmpeg 2>/dev/null | wc -l || true)"
[[ "$FFCOUNT_AFTER" == '0' ]] || fatal "UNEXPECTED_FFMPEG_AFTER:$FFCOUNT_AFTER"

for old in "${DEPRECATED_CHANNELS[@]}"; do
  [[ ! -e "$REPO/channels/$old" ]] || fatal "DEPRECATED_CHANNEL_REAPPEARED:$old"
done
python3 - "$REPO/catalog/channels.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
assert x['company_domain']=='tpsolutions.com.br'
assert x['media_domain']=='studiosatweb.com.br'
expected={
'radioprincipal':'radio.studiosatweb.com.br',
'radiopop':'radiopop.studiosatweb.com.br',
'radiorock':'radiorock.studiosatweb.com.br',
'radioclassicas':'radioclassicas.studiosatweb.com.br',
'radiocountry':'radiocountry.studiosatweb.com.br',
'tvkids':'tvkids.studiosatweb.com.br',
'tvteens':'tvteens.studiosatweb.com.br',
'tvviva':'tvviva.studiosatweb.com.br',
'tvmaisjovem':'tvmaisjovem.studiosatweb.com.br'}
actual={r['channel_id']:r['public_fqdn'] for r in x['channels']}
assert actual==expected, (actual,expected)
PY
log 'NAMING_CONTRACT=PASS INTERNAL_NO_MAIN=YES MEDIA_DOMAIN=studiosatweb.com.br HOST_DOMAIN=tpsolutions.com.br'

section 'R07 — BLOCKER CLASSIFICATION + EVIDENCE'
CONTENT_FILES="$(find "$REPO/channels" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.wav' -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \) -printf '.' 2>/dev/null | wc -c)"
NS2_A="$(dig +short ns2.tpsolutions.com.br A 2>/dev/null | head -1 || true)"
DS_STUDIO="$(dig +short studiosatweb.com.br DS 2>/dev/null | head -1 || true)"

log "CORE_AFTER NGINX=active BIND=active MEDIAMTX=active FFMPEG=$FFCOUNT_AFTER CONTENT_FILES=$CONTENT_FILES"
[[ "$CONTENT_FILES" == '0' ]] && log 'BLOCKER=CONTENT_NOT_PRESENT_IN_NEW_REPOSITORY'
[[ -z "$NS2_A" ]] && log 'BLOCKER=NS2_PUBLIC_A_NOT_RESOLVED'
[[ -n "$DS_STUDIO" ]] && log 'BLOCKER_CHECK_REQUIRED=STUDIOSATWEB_PARENT_DS_EXISTS_VALIDATE_BEFORE_DNSSEC_CUTOVER'

{
  echo "RUN_ID=$RUN_ID"
  echo "HOST=$HOST_FQDN"
  echo "GCP_INSTANCE=$GCP_INSTANCE"
  echo "GCP_PRIVATE=$GCP_PRIVATE"
  echo "GCP_PUBLIC=$GCP_PUBLIC"
  echo "COMPANY_DOMAIN=$COMPANY_DOMAIN"
  echo "MEDIA_DOMAIN=$MEDIA_DOMAIN"
  echo "CANONICAL_CHANNELS=${CHANNELS[*]}"
  echo 'NGINX=active'
  echo 'BIND=active'
  echo 'MEDIAMTX=active'
  echo 'MEDIAMTX_CONFIGURED_PATHS=9'
  echo 'MEDIAMTX_RUNTIME_PATHS=0_EXPECTED_WITHOUT_PUBLISHERS'
  echo 'FFMPEG_ACTIVE=0'
  echo "CONTENT_FILES=$CONTENT_FILES"
  echo "NS2_A=${NS2_A:-ABSENT}"
  echo "STUDIOSATWEB_DS=${DS_STUDIO:-ABSENT}"
} > "$BACKUP/FINAL-STATE.txt"
sha256sum "$MTX_CFG" "$REPO/catalog/channels.json" "$BACKUP/FINAL-STATE.txt" > "$BACKUP/FINAL-SHA256SUMS.txt"

trap - ERR INT TERM
MUTATED_MTX=0
section 'FOUNDATION COMPLETE'
log 'RESULT=PASS_FOUNDATION_R00_R07_V2_1'
log 'NEXT_AUTOMATIC_TRACK=MEDIA_DATA_PLANE -> PUBLIC_EDGE -> DNS_NS2_DNSSEC -> OBSERVABILITY_ACCEPTANCE'
log "REPORT=$REPORT"
log "BACKUP=$BACKUP"
exit 0
