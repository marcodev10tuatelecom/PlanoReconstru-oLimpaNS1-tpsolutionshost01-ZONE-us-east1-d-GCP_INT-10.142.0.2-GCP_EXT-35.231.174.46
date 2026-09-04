# Estado Clean-Room NS1 — 2026-09-04

## Identidade

- Cloud resource: `tpsolutionshost01`
- Role: `NS1`
- Hostname/FQDN: `ns1.tpsolutions.com.br`
- GCP private: `10.142.0.2`
- GCP public: `35.231.174.46`

## Mudança já executada

A árvore histórica `/srv/tpsmedia` foi isolada sob `/srv/tpsmedia-legacy-*` e uma nova árvore base foi criada. O hostname foi corrigido para `ns1.tpsolutions.com.br`.

## RX pós-mudança fornecido pelo operador

- Nginx: `active`
- BIND: `active`
- MediaMTX: `inactive`
- FFmpeg ativos: `0`
- MediaMTX paths runtime: `0`
- porta 443: `0` no resumo

O coletor imprimiu `NS3`, mas isto é classificado como erro de rótulo do coletor; não altera a função do nó.

## Decisão

Não voltar a copiar a árvore legada inteira para `/srv/tpsmedia`. O legado é fonte forense. Dados autoritativos são promovidos seletivamente para a nova estrutura.

Próxima execução: `TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh`.
