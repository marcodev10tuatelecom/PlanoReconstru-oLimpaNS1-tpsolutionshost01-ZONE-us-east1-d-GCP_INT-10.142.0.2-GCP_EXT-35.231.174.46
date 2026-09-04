# Estado Clean-Room NS1 — 2026-09-04

## Identidade

- Cloud resource: `tpsolutionshost01`
- Role: `NS1`
- Hostname/FQDN: `ns1.tpsolutions.com.br`
- GCP private: `10.142.0.2`
- GCP public: `35.231.174.46`

## Mudanças já executadas/informadas pelo operador

- A árvore histórica `/srv/tpsmedia` foi isolada sob `/srv/tpsmedia-legacy-*`.
- Uma nova árvore base `/srv/tpsmedia` foi criada.
- Hostname foi corrigido para `ns1.tpsolutions.com.br`.
- O operador informou padronização dos nomes das emissoras para a forma final sem `-main`.

A execução externa/Grok é tratada como **estado informado**, não como certificação. O Runner Foundation v2.1.0 verifica e normaliza o estado antes de declarar PASS.

## Nomenclatura definitiva

IDs internos/pastas/paths:

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

Domínios:

- infraestrutura/hosting: `tpsolutions.com.br`;
- emissoras: `studiosatweb.com.br`.

`radioprincipal` publica como `radio.studiosatweb.com.br`; os demais usam o ID como label público, por exemplo `radiorock.studiosatweb.com.br` e `tvkids.studiosatweb.com.br`.

## RX pós-mudança informado

- Nginx: `active`
- BIND: `active`
- MediaMTX: `inactive`
- FFmpeg ativos: `0`
- MediaMTX paths runtime: `0`
- porta 443: `0` no resumo

O coletor imprimiu `NS3`; isto é erro de rótulo. A função do nó é NS1.

## Decisão

- Não copiar a árvore legada inteira de volta.
- Não reintroduzir nomes `*-main`, `-32`, `-64`, `-clean` ou autoridades antigas.
- Preservar qualquer diretório antigo encontrado em backup antes de removê-lo da autoridade.
- CAS permanece parte da arquitetura desde a fundação.

## Próxima autoridade executável

`TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh`

A versão v2.0.0 está superseded e não deve ser usada para nova execução.
