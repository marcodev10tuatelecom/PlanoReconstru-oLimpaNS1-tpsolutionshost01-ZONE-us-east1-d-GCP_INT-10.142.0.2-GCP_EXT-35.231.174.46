#!/usr/bin/env bash
# ============================================================
# TPS-NS1-CLEANROOM-MASTER-FOUNDATION v2.2.1
# Migration-aware foundation runner for the exact post-SCRIPT-02B state.
# Canonical IDs: radioprincipal radiopop radiorock radioclassicas
#                radiocountry tvkids tvteens tvviva tvmaisjovem
# Media domain: studiosatweb.com.br
# ============================================================
set -Eeuo pipefail
IFS=$'\n\t'
umask 027
export LC_ALL=C LANG=C TZ=UTC

PROGRAM='TPS-NS1-CLEANROOM-MASTER-FOUNDATION'
VERSION='2.2.1'
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

FINAL_CHANNELS=(
  radioprincipal radiopop radiorock radioclassicas radiocountry
  tvkids tvteens tvviva tvmaisjovem
)
LEGACY_9=(
  radio-main radio-pop radio-rock radio-classicas radio-country
  tvkids-main tvteens-main tvviva-main tvmaisjovem-main
)
DEPRECATED_CHANNELS=(
  radio-main radio-pop radio-rock radio-classicas radio-country
  tvkids-main tvteens-main tvviva-main tvmaisjovem-main
  radiotv-main tv-main tv2-main tv2-clean tv-main-clean tvkids-clean
  tv-crista-main tv-jovem-main radio-main-32 radio-main-64
)

RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${PROGRAM}-${VERSION}-${RUN_TS}"
WORK="/var/tmp/${RUN_ID}"
BACKUP="/root/TPS-NS1-CLEANROOM-BACKUP-${RUN_TS}"
REPORT="/root/${RUN_ID}.report.txt"

LAB_PID=''
LAB_PUBLISHER_PID=''
BIND_UNIT=''
MTX_PID_BEFORE='0'
MTX_RESTARTS_BEFORE='0'
NGINX_PID_BEFORE='0'
BIND_PID_BEFORE='0'
ORIGINAL_PATHS_FILE=''
ORIGINAL_PATHS_SORTED=''
MUTATED_MTX=0
MUTATED_REPO=0
MUTATED_CATALOG=0
CATALOG_EXISTED_BEFORE=0
CREATED_FINAL_CHANNELS=()
ROLLBACK_RUNNING=0

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$REPORT"
}
section() {
  printf '\n============================================================\n%s\n============================================================\n' "$*" | tee -a "$REPORT"
}
have() { command -v "$1" >/dev/null 2>&1; }

cleanup_lab() {
  if [[ -n "${LAB_PUBLISHER_PID:-}" ]] && kill -0 "$LAB_PUBLISHER_PID" 2>/dev/null; then
    kill -TERM "$LAB_PUBLISHER_PID" 2>/dev/null || true
    wait "$LAB_PUBLISHER_PID" 2>/dev/null || true
  fi
  LAB_PUBLISHER_PID=''

  if [[ -n "${LAB_PID:-}" ]] && kill -0 "$LAB_PID" 2>/dev/null; then
    kill -TERM "$LAB_PID" 2>/dev/null || true
    for _ in {1..5}; do
      kill -0 "$LAB_PID" 2>/dev/null || break
      sleep 1
    done
    kill -KILL "$LAB_PID" 2>/dev/null || true
    wait "$LAB_PID" 2>/dev/null || true
  fi
  LAB_PID=''
}

api_paths_sorted() {
  curl -fsS --max-time 3 http://127.0.0.1:9997/v3/paths/list |
    python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join(sorted(x.get("name","") for x in d.get("items",[]) if x.get("name"))))'
}

api_assert_all_idle() {
  curl -fsS --max-time 3 http://127.0.0.1:9997/v3/paths/list |
    python3 -c '
import json,sys
D=json.load(sys.stdin)
bad=[]
for x in D.get("items",[]):
    readers=x.get("readers") or []
    if x.get("ready") is True or x.get("online") is True or x.get("source") is not None or len(readers)>0:
        bad.append({"name":x.get("name"),"ready":x.get("ready"),"online":x.get("online"),"source":x.get("source"),"readers":len(readers)})
if bad:
    print(json.dumps(bad,ensure_ascii=False))
    raise SystemExit(1)
'
}

restore_deprecated_dirs() {
  [[ -d "$BACKUP/retired-deprecated-channel-dirs" ]] || return 0
  mkdir -p "$REPO/channels"
  shopt -s nullglob
  local src base dst
  for src in "$BACKUP"/retired-deprecated-channel-dirs/*; do
    base="$(basename "$src")"
    dst="$REPO/channels/$base"
    if [[ -e "$dst" ]]; then
      log "ROLLBACK_REPO_COLLISION=$dst"
      continue
    fi
    mv "$src" "$dst" || true
    log "ROLLBACK_REPO_RESTORED=$base"
  done
  shopt -u nullglob
}

rollback_final_repository_artifacts() {
  local catalog="$REPO/catalog/channels.json"
  if (( MUTATED_CATALOG == 1 )); then
    if (( CATALOG_EXISTED_BEFORE == 1 )) && [[ -f "$BACKUP/channels.json.before" ]]; then
      install -o tps-playout -g tps-media -m 0640 "$BACKUP/channels.json.before" "$catalog" || true
      log 'ROLLBACK_CATALOG=RESTORED'
    else
      rm -f "$catalog" || true
      log 'ROLLBACK_CATALOG=REMOVED_CREATED_FILE'
    fi
  fi

  local ch base d incomplete=0
  for ch in "${CREATED_FINAL_CHANNELS[@]:-}"; do
    [[ -n "$ch" ]] || continue
    base="$REPO/channels/$ch"
    for d in ready logs quarantine incoming state playlists refs; do
      rmdir "$base/$d" 2>/dev/null || true
    done
    if rmdir "$base" 2>/dev/null; then
      log "ROLLBACK_FINAL_CHANNEL_REMOVED=$ch"
    elif [[ -d "$base" ]]; then
      incomplete=1
      log "ROLLBACK_FINAL_CHANNEL_NONEMPTY_PRESERVED=$ch"
    fi
  done
  (( incomplete == 0 )) || log 'ROLLBACK_FINAL_CHANNELS=PARTIAL_NONEMPTY_DATA_PRESERVED'
}

wait_paths_equal() {
  local expected="$1"
  local current=''
  for _ in {1..30}; do
    if current="$(api_paths_sorted 2>/dev/null)" && [[ "$current" == "$expected" ]]; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

rollback() {
  local rc="${1:-1}"
  local reason="${2:-UNSPECIFIED}"
  if (( ROLLBACK_RUNNING == 1 )); then
    exit "$rc"
  fi
  ROLLBACK_RUNNING=1
  trap - ERR INT TERM
  cleanup_lab
  log "ROLLBACK=START REASON=$reason"

  if (( MUTATED_MTX == 1 )) && [[ -f "$BACKUP/mediamtx.yml.before" ]]; then
    install -o root -g tpsmedia -m 0640 "$BACKUP/mediamtx.yml.before" "$MTX_CFG" || true
    if systemctl is-active --quiet "$MTX_UNIT"; then
      if wait_paths_equal "$ORIGINAL_PATHS_SORTED"; then
        log 'ROLLBACK_MEDIAMTX=PASS_HOT_RELOAD_RESTORED'
      else
        log 'ROLLBACK_MEDIAMTX=INCOMPLETE_MANUAL_INTERVENTION_REQUIRED'
      fi
    else
      log 'ROLLBACK_MEDIAMTX=SERVICE_NOT_ACTIVE_MANUAL_INTERVENTION_REQUIRED'
    fi
  fi

  if (( MUTATED_REPO == 1 || MUTATED_CATALOG == 1 )); then
    rollback_final_repository_artifacts
  fi
  if (( MUTATED_REPO == 1 )); then
    restore_deprecated_dirs
  fi

  log "RESULT=FAIL RC=$rc REASON=$reason"
  exit "$rc"
}

fatal() {
  local reason="$1"
  log "FATAL=$reason"
  rollback 1 "$reason"
}

on_err() {
  local rc=$?
  rollback "$rc" "UNCAUGHT_ERR_LINE_${BASH_LINENO[0]:-UNKNOWN}"
}
trap on_err ERR
trap 'rollback 130 INTERRUPTED' INT TERM

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'FATAL=RUN_AS_ROOT_REQUIRED' >&2; exit 1; }
mkdir -p "$WORK"
touch "$REPORT"
chmod 0600 "$REPORT"

section "${PROGRAM} v${VERSION}"
log "RUN_ID=$RUN_ID"
log 'MODE=EXACT_STATE_ANALYZE_LAB_MIGRATE_VALIDATE'
log 'NORMAL_PATH_RESTART=FORBIDDEN'
log "COMPANY_DOMAIN=$COMPANY_DOMAIN"
log "MEDIA_DOMAIN=$MEDIA_DOMAIN"
log "FINAL_CHANNELS=${FINAL_CHANNELS[*]}"

section 'R00 — SELF TEST + EXACT CURRENT-STATE ADMISSION'
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
bash -n "$SCRIPT_PATH" || fatal 'SELF_BASH_N_FAIL'
have shellcheck || fatal 'SHELLCHECK_REQUIRED'
shellcheck -S warning "$SCRIPT_PATH" || fatal 'SELF_SHELLCHECK_FAIL'
log 'SELF_SHELLCHECK=PASS'

for c in curl python3 systemctl install sha256sum ffmpeg ffprobe timeout runuser dig nginx named-checkconf find pgrep getent usermod; do
  have "$c" || fatal "MISSING_COMMAND:$c"
done
python3 - <<'PY' >/dev/null || fatal 'PYYAML_MISSING'
import yaml
PY

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
log "IDENTITY=PASS HOST=$HOST_FQDN INSTANCE=$GCP_INSTANCE PRIVATE=$GCP_PRIVATE PUBLIC=$GCP_PUBLIC"

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
systemctl is-active --quiet "$MTX_UNIT" || fatal 'MEDIAMTX_EXPECTED_ACTIVE_AFTER_SCRIPT_02B'
[[ -x "$MTX_BIN" ]] || fatal "MEDIAMTX_BINARY_MISSING:$MTX_BIN"
[[ -f "$MTX_CFG" ]] || fatal "MEDIAMTX_CONFIG_MISSING:$MTX_CFG"
id tpsmedia >/dev/null 2>&1 || fatal 'TPSMEDIA_ACCOUNT_MISSING'
TPSMEDIA_GROUP="$(id -gn tpsmedia)"
[[ -n "$TPSMEDIA_GROUP" ]] || fatal 'TPSMEDIA_PRIMARY_GROUP_UNRESOLVED'
# WORK is created by root under umask 027. The MediaMTX LAB runs as tpsmedia,
# so the service account must be able to traverse WORK before reading the candidate.
chown root:"$TPSMEDIA_GROUP" "$WORK"
chmod 0750 "$WORK"

FFCOUNT="$(pgrep -x ffmpeg 2>/dev/null | wc -l || true)"
[[ "$FFCOUNT" == '0' ]] || fatal "FFMPEG_ACTIVE_UNEXPECTED:$FFCOUNT"
api_assert_all_idle || fatal 'MEDIAMTX_HAS_ACTIVE_SOURCE_OR_READER'

MTX_PID_BEFORE="$(systemctl show "$MTX_UNIT" -p MainPID --value)"
MTX_RESTARTS_BEFORE="$(systemctl show "$MTX_UNIT" -p NRestarts --value)"
NGINX_PID_BEFORE="$(systemctl show nginx.service -p MainPID --value)"
BIND_PID_BEFORE="$(systemctl show "$BIND_UNIT" -p MainPID --value)"

ORIGINAL_PATHS_FILE="$WORK/original-paths.txt"
api_paths_sorted > "$ORIGINAL_PATHS_FILE"
ORIGINAL_PATHS_SORTED="$(cat "$ORIGINAL_PATHS_FILE")"
LEGACY_SORTED="$(printf '%s\n' "${LEGACY_9[@]}" | sort)"
FINAL_SORTED="$(printf '%s\n' "${FINAL_CHANNELS[@]}" | sort)"
if [[ "$ORIGINAL_PATHS_SORTED" == "$LEGACY_SORTED" ]]; then
  CURRENT_NAMING_STATE='LEGACY_9_FROM_SCRIPT_02B'
elif [[ "$ORIGINAL_PATHS_SORTED" == "$FINAL_SORTED" ]]; then
  CURRENT_NAMING_STATE='FINAL_9_ALREADY_APPLIED'
else
  printf '%s\n' "$ORIGINAL_PATHS_SORTED" | tee -a "$REPORT"
  fatal 'UNEXPECTED_MEDIAMTX_PATH_SET'
fi
log "CURRENT_NAMING_STATE=$CURRENT_NAMING_STATE PATHS=9 ALL_IDLE=YES"
log "CORE_BEFORE MTX_PID=$MTX_PID_BEFORE MTX_NRESTARTS=$MTX_RESTARTS_BEFORE NGINX_PID=$NGINX_PID_BEFORE BIND_PID=$BIND_PID_BEFORE"

section 'R01 — FORENSIC BACKUP + REPOSITORY COLLISION INVENTORY'
mkdir -p "$BACKUP/systemd" "$BACKUP/retired-deprecated-channel-dirs"
chmod 0700 "$BACKUP"
for p in /etc/tpsmedia /etc/nginx /etc/bind; do
  [[ -e "$p" ]] && cp -a "$p" "$BACKUP/"
done
find /etc/systemd/system -maxdepth 2 -type f -name 'tps-*' -exec cp -a --parents {} "$BACKUP/systemd/" \; 2>/dev/null || true
find /srv -maxdepth 1 -type d -name 'tpsmedia-legacy-*' -printf '%p\n' > "$BACKUP/legacy-paths.txt"
find /srv/tpsmedia -xdev -maxdepth 6 -printf '%M %u:%g %s %p\n' 2>/dev/null > "$BACKUP/tpsmedia-tree-before.txt" || true
cp -a "$MTX_CFG" "$BACKUP/mediamtx.yml.before"
cp -a "$ORIGINAL_PATHS_FILE" "$BACKUP/mediamtx-paths-before.txt"
if [[ -f "$REPO/catalog/channels.json" ]]; then
  cp -a "$REPO/catalog/channels.json" "$BACKUP/channels.json.before"
  CATALOG_EXISTED_BEFORE=1
fi
sha256sum "$SCRIPT_PATH" "$MTX_CFG" > "$BACKUP/prechange.sha256"

if [[ -d "$REPO/channels" ]]; then
  for old in "${DEPRECATED_CHANNELS[@]}"; do
    olddir="$REPO/channels/$old"
    [[ -d "$olddir" ]] || continue
    files="$(find "$olddir" -type f -o -type l 2>/dev/null | wc -l)"
    bytes="$(du -sb "$olddir" 2>/dev/null | awk '{print $1}' || echo 0)"
    log "DEPRECATED_REPO_DIR=$old FILES=$files BYTES=$bytes ACTION=RETIRE_AFTER_LAB_PRESERVE"
  done
fi
log "BACKUP=PASS PATH=$BACKUP"

section 'R02 — BUILD FINAL MEDIAMTX CANDIDATE + STATIC CONTRACT'
CAND="$WORK/mediamtx.final.yml"
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
assert list(d.get('paths',{}).keys()) == exp
assert d['pathDefaults']['overridePublisher'] is False
assert d['api'] is True and d['apiAddress']=='127.0.0.1:9997'
assert d['metrics'] is True and d['metricsAddress']=='127.0.0.1:9998'
assert d['hls'] is True and d['hlsAddress']=='127.0.0.1:8888'
assert d['rtmp'] is True and d['rtmpAddress']==':1935'
assert d['rtsp'] is False and d['webrtc'] is False and d['srt'] is False
PY
# Candidate is root-owned but explicitly readable by the MediaMTX service account.
# This fixes the v2.2.0 LAB failure where WORK/CAND were root-only under umask 027.
chown root:"$TPSMEDIA_GROUP" "$CAND"
chmod 0640 "$CAND"
runuser -u tpsmedia -- test -r "$CAND" || fatal 'LAB_CANDIDATE_NOT_READABLE_BY_TPSMEDIA'
runuser -u tpsmedia -- test -x "$WORK" || fatal 'LAB_WORKDIR_NOT_TRAVERSABLE_BY_TPSMEDIA'
log "LAB_FILE_PERMISSIONS=PASS WORK=$(stat -c '%U:%G:%a' "$WORK") CAND=$(stat -c '%U:%G:%a' "$CAND")"
log "CANDIDATE=PASS SHA256=$(sha256sum "$CAND" | awk '{print $1}')"

section 'R03 — REAL ISOLATED LAB: FINAL NAMES + RTMP + HLS + DECODE'
LABLOG="$WORK/mediamtx-lab.log"
runuser -u tpsmedia -- env \
  MTX_APIADDRESS=127.0.0.1:19997 \
  MTX_METRICSADDRESS=127.0.0.1:19998 \
  MTX_RTMPADDRESS=127.0.0.1:11935 \
  MTX_HLSADDRESS=127.0.0.1:18888 \
  "$MTX_BIN" "$CAND" >"$LABLOG" 2>&1 &
LAB_PID=$!

LAB_FINAL_SORTED=''
for _ in {1..30}; do
  if LAB_FINAL_SORTED="$(curl -fsS --max-time 1 http://127.0.0.1:19997/v3/paths/list 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join(sorted(x["name"] for x in d.get("items",[]))))' 2>/dev/null)" && [[ "$LAB_FINAL_SORTED" == "$FINAL_SORTED" ]]; then
    break
  fi
  sleep 0.5
done
[[ "$LAB_FINAL_SORTED" == "$FINAL_SORTED" ]] || { cat "$LABLOG" >&2 || true; fatal 'LAB_FINAL_PATH_SET_FAIL'; }
curl -fsS --max-time 2 http://127.0.0.1:19998/metrics >/dev/null || { cat "$LABLOG" >&2 || true; fatal 'LAB_METRICS_FAIL'; }

ffmpeg -hide_banner -loglevel error -re -f lavfi -i 'sine=frequency=997:sample_rate=48000' \
  -t 20 -c:a aac -b:a 96k -ar 48000 -ac 2 -f flv \
  rtmp://127.0.0.1:11935/radiopop >"$WORK/lab-publisher.log" 2>&1 &
LAB_PUBLISHER_PID=$!

READY=0
for _ in {1..30}; do
  if curl -fsS --max-time 1 http://127.0.0.1:19997/v3/paths/list | python3 -c '
import json,sys
D=json.load(sys.stdin)
for x in D.get("items",[]):
    if x.get("name")=="radiopop" and x.get("ready") is True and int(x.get("inboundBytes") or x.get("bytesReceived") or 0)>0:
        raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null; then
    READY=1
    break
  fi
  sleep 0.5
done
(( READY == 1 )) || { cat "$WORK/lab-publisher.log" >&2 || true; cat "$LABLOG" >&2 || true; fatal 'LAB_RTMP_NOT_READY_OR_NO_BYTES'; }

HLS=0
for _ in {1..40}; do
  if curl -fsS --max-time 1 http://127.0.0.1:18888/radiopop/index.m3u8 > "$WORK/lab.m3u8" 2>/dev/null && grep -q '^#EXTM3U' "$WORK/lab.m3u8"; then
    HLS=1
    break
  fi
  sleep 0.5
done
(( HLS == 1 )) || { cat "$LABLOG" >&2 || true; fatal 'LAB_HLS_FAIL'; }

timeout 15s ffprobe -v error -read_intervals '%+3' -show_entries stream=codec_type -of default=nw=1:nk=1 \
  http://127.0.0.1:18888/radiopop/index.m3u8 > "$WORK/lab-ffprobe.txt" 2> "$WORK/lab-ffprobe.err" || fatal 'LAB_HLS_DECODE_FAIL_OR_TIMEOUT'
grep -qx 'audio' "$WORK/lab-ffprobe.txt" || fatal 'LAB_HLS_AUDIO_TRACK_MISSING'

wait "$LAB_PUBLISHER_PID" || fatal 'LAB_PUBLISHER_EXIT_FAIL'
LAB_PUBLISHER_PID=''
cleanup_lab
log 'LAB=PASS FINAL_PATHS=9 RTMP=PASS BYTES=PASS HLS=PASS DECODE=PASS'

section 'R04 — TRANSACTIONAL RETIREMENT OF DEPRECATED REPOSITORY NAMES'
mkdir -p "$REPO/channels"
for old in "${DEPRECATED_CHANNELS[@]}"; do
  olddir="$REPO/channels/$old"
  [[ -d "$olddir" ]] || continue
  [[ ! -e "$BACKUP/retired-deprecated-channel-dirs/$old" ]] || fatal "BACKUP_COLLISION:$old"
  mv "$olddir" "$BACKUP/retired-deprecated-channel-dirs/$old"
  MUTATED_REPO=1
  log "RETIRED_DEPRECATED_CHANNEL=$old PRESERVED_AT=$BACKUP/retired-deprecated-channel-dirs/$old"
done

section 'R05 — ATOMIC MEDIAMTX HOT-RELOAD MIGRATION; NO RESTART'
install -o root -g tpsmedia -m 0640 "$CAND" "$MTX_CFG"
MUTATED_MTX=1
wait_paths_equal "$FINAL_SORTED" || fatal 'PRODUCTION_HOT_RELOAD_DID_NOT_CONVERGE_TO_FINAL_9'
systemctl is-active --quiet "$MTX_UNIT" || fatal 'MEDIAMTX_DIED_AFTER_HOT_RELOAD'
MTX_PID_AFTER="$(systemctl show "$MTX_UNIT" -p MainPID --value)"
MTX_RESTARTS_AFTER="$(systemctl show "$MTX_UNIT" -p NRestarts --value)"
[[ "$MTX_PID_AFTER" == "$MTX_PID_BEFORE" ]] || fatal "MEDIAMTX_PID_CHANGED:$MTX_PID_BEFORE:$MTX_PID_AFTER"
[[ "$MTX_RESTARTS_AFTER" == "$MTX_RESTARTS_BEFORE" ]] || fatal "MEDIAMTX_NRESTARTS_CHANGED:$MTX_RESTARTS_BEFORE:$MTX_RESTARTS_AFTER"
api_assert_all_idle || fatal 'FINAL_PATHS_NOT_IDLE_AFTER_MIGRATION'
curl -fsS --max-time 3 http://127.0.0.1:9998/metrics >/dev/null || fatal 'PRODUCTION_METRICS_FAIL'
log 'MEDIAMTX_MIGRATION=PASS HOT_RELOAD=YES PID_UNCHANGED=YES NRESTARTS_UNCHANGED=YES FINAL_PATHS=9'

section 'R06 — SERVICE IDENTITIES + FINAL CAS SKELETON'
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

for ch in "${FINAL_CHANNELS[@]}"; do
  base="$REPO/channels/$ch"
  if [[ ! -d "$base" ]]; then
    CREATED_FINAL_CHANNELS+=("$ch")
  fi
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
MUTATED_CATALOG=1
chown tps-playout:tps-media "$REPO/catalog/channels.json"
chmod 0640 "$REPO/catalog/channels.json"

ACTUAL_SORTED="$(find "$REPO/channels" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"
[[ "$ACTUAL_SORTED" == "$FINAL_SORTED" ]] || fatal 'FINAL_REPOSITORY_CHANNEL_SET_MISMATCH'
log 'REPOSITORY=PASS CAS=ENABLED FINAL_CHANNELS=9 OLD_NAMES_ABSENT=YES'

section 'R07 — FINAL INVARIANTS + EVIDENCE'
[[ "$(systemctl show nginx.service -p MainPID --value)" == "$NGINX_PID_BEFORE" ]] || fatal 'NGINX_PID_CHANGED_UNEXPECTEDLY'
[[ "$(systemctl show "$BIND_UNIT" -p MainPID --value)" == "$BIND_PID_BEFORE" ]] || fatal 'BIND_PID_CHANGED_UNEXPECTEDLY'
nginx -t >/dev/null 2>&1 || fatal 'NGINX_CONFIG_BROKEN'
named-checkconf >/dev/null 2>&1 || fatal 'BIND_CONFIG_BROKEN'
[[ "$(pgrep -x ffmpeg 2>/dev/null | wc -l || true)" == '0' ]] || fatal 'FFMPEG_PRESENT_AT_END'
wait_paths_equal "$FINAL_SORTED" || fatal 'FINAL_MEDIAMTX_PATH_SET_CHANGED'
api_assert_all_idle || fatal 'FINAL_MEDIAMTX_NOT_IDLE'

CONTENT_FILES="$(find "$REPO/channels" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.wav' -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \) -printf '.' 2>/dev/null | wc -c)"
NS2_A="$(dig +short ns2.tpsolutions.com.br A 2>/dev/null | head -1 || true)"
DS_STUDIO="$(dig +short studiosatweb.com.br DS 2>/dev/null | head -1 || true)"

cat > "$BACKUP/FINAL-STATE.txt" <<STATE
RUN_ID=$RUN_ID
HOST=$HOST_FQDN
GCP_INSTANCE=$GCP_INSTANCE
GCP_PRIVATE=$GCP_PRIVATE
GCP_PUBLIC=$GCP_PUBLIC
COMPANY_DOMAIN=$COMPANY_DOMAIN
MEDIA_DOMAIN=$MEDIA_DOMAIN
CURRENT_NAMING_STATE_BEFORE=$CURRENT_NAMING_STATE
FINAL_CHANNELS=${FINAL_CHANNELS[*]}
MEDIAMTX=active
MEDIAMTX_PID_BEFORE=$MTX_PID_BEFORE
MEDIAMTX_PID_AFTER=$MTX_PID_AFTER
MEDIAMTX_NRESTARTS_BEFORE=$MTX_RESTARTS_BEFORE
MEDIAMTX_NRESTARTS_AFTER=$MTX_RESTARTS_AFTER
MEDIAMTX_CONFIGURED_PATHS=9_FINAL
MEDIAMTX_READY_PATHS=0_EXPECTED_WITHOUT_PUBLISHERS
FFMPEG_ACTIVE=0
CONTENT_FILES=$CONTENT_FILES
NS2_A=${NS2_A:-ABSENT}
STUDIOSATWEB_DS=${DS_STUDIO:-ABSENT}
STATE
sha256sum "$MTX_CFG" "$REPO/catalog/channels.json" "$BACKUP/FINAL-STATE.txt" > "$BACKUP/FINAL-SHA256SUMS.txt"

log "CORE_AFTER NGINX=UNCHANGED BIND=UNCHANGED MEDIAMTX=active FINAL_PATHS=9 FFMPEG=0 CONTENT_FILES=$CONTENT_FILES"
[[ "$CONTENT_FILES" == '0' ]] && log 'BLOCKER=CONTENT_NOT_PRESENT_IN_FINAL_REPOSITORY'
[[ -z "$NS2_A" ]] && log 'BLOCKER=NS2_PUBLIC_A_NOT_RESOLVED'
[[ -n "$DS_STUDIO" ]] && log 'BLOCKER_CHECK_REQUIRED=STUDIOSATWEB_PARENT_DS_EXISTS_VALIDATE_BEFORE_DNSSEC_CUTOVER'

trap - ERR INT TERM
MUTATED_MTX=0
MUTATED_REPO=0
MUTATED_CATALOG=0
section 'FOUNDATION MIGRATION COMPLETE'
log 'RESULT=PASS_FOUNDATION_R00_R07_V2_2_1'
log 'NOMENCLATURE=FINAL_NO_MAIN'
log 'PUBLIC_MEDIA_DOMAIN=studiosatweb.com.br'
log "REPORT=$REPORT"
log "BACKUP=$BACKUP"
exit 0
