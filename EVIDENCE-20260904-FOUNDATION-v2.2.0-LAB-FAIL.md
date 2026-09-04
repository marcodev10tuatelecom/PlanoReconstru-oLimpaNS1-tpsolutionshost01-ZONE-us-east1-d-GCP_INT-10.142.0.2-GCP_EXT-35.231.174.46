# Evidência — Foundation v2.2.0 — FAIL SAFE em R03

Data UTC da execução: `2026-09-04T18:04:40Z`.

## Pré-check comprovado

- SHA-256 do runner v2.2.0: PASS
- `bash -n`: PASS
- ShellCheck: PASS
- Host/FQDN: `ns1.tpsolutions.com.br`
- GCP instance: `tpsolutionshost01`
- Private IP: `10.142.0.2`
- Public IP: `35.231.174.46`
- Estado de nomenclatura: `LEGACY_9_FROM_SCRIPT_02B`
- 9 paths ociosos: PASS
- MediaMTX PID: `36164`
- MediaMTX `NRestarts=0`
- Nginx PID: `1002`
- BIND PID: `917`

## R01

Backup forense criado em:

`/root/TPS-NS1-CLEANROOM-BACKUP-20260904T180440Z`

Os 9 diretórios legados de repositório foram inventariados com `FILES=0` e `BYTES=0`; nenhum deles havia sido retirado da autoridade ainda.

## R02

Candidato MediaMTX passou contrato estático.

Candidate SHA-256:

`6e3c25f22c86b7e65e5b80da4676b2cd616a33a6ad86525a86fd792633c0f5ea`

## R03 — falha

Erro primário do binário MediaMTX LAB:

`ERR: open /var/tmp/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-2.2.0-20260904T180440Z/mediamtx.final.yml: permission denied`

Gate final:

`FATAL=LAB_FINAL_PATH_SET_FAIL`

Rollback reportado:

`ROLLBACK=START REASON=LAB_FINAL_PATH_SET_FAIL`

`RESULT=FAIL RC=1 REASON=LAB_FINAL_PATH_SET_FAIL`

## Causa raiz

O runner usa `umask 027`. O diretório `WORK` e `mediamtx.final.yml` foram criados por `root`, enquanto o MediaMTX LAB foi iniciado com `runuser -u tpsmedia`. O usuário de serviço não possuía traversal/read suficiente para abrir o candidato.

## Classificação de impacto

**SAFE PRE-MUTATION FAIL.**

A falha ocorreu antes de R04 (retirement dos diretórios legados) e antes de R05 (hot reload do MediaMTX de produção). Portanto:

- configuração MediaMTX de produção não foi substituída;
- paths de produção continuaram os 9 legados do SCRIPT 02B;
- diretórios legados permaneceram no lugar;
- Nginx/BIND não foram alterados;
- nenhum publisher FFmpeg foi deixado ativo.

## Correção

Substituto: `TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.sh`.

A v2.2.1 corrige permissões do LAB e adiciona hardening de rollback/timeout antes de nova tentativa.
