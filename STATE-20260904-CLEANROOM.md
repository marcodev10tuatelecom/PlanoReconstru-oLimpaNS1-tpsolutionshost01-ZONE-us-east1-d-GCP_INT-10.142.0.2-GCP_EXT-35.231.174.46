# Estado Clean-Room NS1 — 2026-09-04

## Identidade

- Cloud resource: `tpsolutionshost01`
- Role: `NS1`
- Hostname/FQDN: `ns1.tpsolutions.com.br`
- GCP private: `10.142.0.2`
- GCP public: `35.231.174.46`

## Mudanças executadas e comprovadas pelo operador

- A árvore histórica `/srv/tpsmedia` foi isolada sob `/srv/tpsmedia-legacy-*`.
- Uma nova árvore base `/srv/tpsmedia` foi criada.
- O hostname foi corrigido para `ns1.tpsolutions.com.br`.
- O SCRIPT 02B reescreveu a configuração do MediaMTX e executou `systemctl restart tps-mediamtx`.
- Após o SCRIPT 02B, o MediaMTX ficou `active` e as portas RTMP/HLS/API ficaram em escuta.

## Estado exato pós-SCRIPT-02B

- Nginx: `active`
- BIND: `active`
- MediaMTX: `active`
- FFmpeg ativos: `0`
- Porta RTMP 1935: escutando
- Porta HLS 8888: escutando
- Porta API 9997: escutando
- Paths configurados na API: `9`
- Paths READY: `0`
- Paths ONLINE: `0`
- Publishers/source: `0`
- Readers: `0`
- Bytes recebidos/enviados: `0`
- HTTPS/443: ainda não certificado neste estado

### Nomes transitórios ainda presentes no MediaMTX

`radio-main`, `radio-pop`, `radio-rock`, `radio-classicas`, `radio-country`, `tvkids-main`, `tvteens-main`, `tvviva-main`, `tvmaisjovem-main`.

Esses nomes são **estado legado transitório introduzido pelo SCRIPT 02B**, não autoridade final.

## Nomenclatura definitiva

IDs internos/pastas/paths finais:

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

Domínios:

- infraestrutura/hosting: `tpsolutions.com.br`;
- emissoras: `studiosatweb.com.br`.

`radioprincipal` publica como `radio.studiosatweb.com.br`; os demais usam o ID final como label público.

## Interpretação correta da API MediaMTX

No runtime atual, `/v3/paths/list` materializa os nove paths configurados mesmo sem publisher. Portanto a métrica correta é:

- `CONFIGURED_PATHS=9`
- `READY_PATHS=0`
- `ONLINE_PATHS=0`

Não usar a expressão `0 paths` para este estado.

## Decisão operacional

- Não copiar a árvore legada inteira de volta.
- Não executar novamente o SCRIPT 02B.
- Não executar o Script 03 destrutivo com `rm -rf /srv/tpsmedia/repository/channels/*`.
- Não executar Foundation v2.0.0 nem v2.1.0.
- Preservar qualquer diretório antigo antes de retirá-lo da autoridade.
- CAS permanece parte da arquitetura desde a fundação.
- Próxima migração deve usar hot reload do MediaMTX, sem novo restart, exigindo PID e `NRestarts` invariantes.

## Próxima autoridade executável

`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh`

PASS esperado: `RESULT=PASS_FOUNDATION_R00_R07_V2_2`.
