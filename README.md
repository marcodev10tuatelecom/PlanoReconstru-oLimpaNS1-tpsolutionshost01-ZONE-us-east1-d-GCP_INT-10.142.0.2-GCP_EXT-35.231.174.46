# Plano de Reconstrução Limpa e Completa — NS1

**Cloud resource:** `tpsolutionshost01`  
**Função TPS:** `NS1`  
**FQDN:** `ns1.tpsolutions.com.br`  
**Zona:** `us-east1-d`  
**IP Interno:** `10.142.0.2`  
**IP Externo:** `35.231.174.46`  
**Data-base:** 2026-09-04  

## Decisão arquitetural

**Não remendar. Reconstruir in-place preservando a VM GCP.** A árvore histórica `/srv/tpsmedia` foi isolada sob `/srv/tpsmedia-legacy-*`; o legado é fonte forense, não autoridade operacional.

## Fronteira de domínios

- Infraestrutura / hosting / servidores: `tpsolutions.com.br`
- Emissoras de rádio e TV: `studiosatweb.com.br`
- Este servidor: `ns1.tpsolutions.com.br`

A nomenclatura definitiva está em [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).

## 9 IDs canônicos definitivos

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

Não criar novamente `-main`, `-32`, `-64`, `-clean`, `-old`, `-new`, `tv2-*`, `tv-crista-*`, `tv-jovem-*` ou `radiotv-main` como autoridade.

Mapeamento público:

- `radioprincipal` → `radio.studiosatweb.com.br`
- `radiopop` → `radiopop.studiosatweb.com.br`
- `radiorock` → `radiorock.studiosatweb.com.br`
- `radioclassicas` → `radioclassicas.studiosatweb.com.br`
- `radiocountry` → `radiocountry.studiosatweb.com.br`
- `tvkids` → `tvkids.studiosatweb.com.br`
- `tvteens` → `tvteens.studiosatweb.com.br`
- `tvviva` → `tvviva.studiosatweb.com.br`
- `tvmaisjovem` → `tvmaisjovem.studiosatweb.com.br`

## Estado pós-clean-room informado pelo operador

| Camada | Estado |
|---|---|
| Hostname | `ns1.tpsolutions.com.br` |
| Nginx | `active` |
| BIND | `active` |
| MediaMTX | `inactive` no último RX pós-mudança |
| FFmpeg | `0` |
| Paths MediaMTX runtime | `0` |
| HTTPS/443 | ausente/não comprovado no último resumo |
| `/srv/tpsmedia` | nova árvore clean-room |
| `/srv/tpsmedia-legacy-*` | legado preservado |

O coletor que imprimiu `NS3` está incorreto para este projeto. Esta máquina é o **NS1 clean-room**.

## Autoridade operacional atual

### Foundation v2.1.0 — executar esta versão

[`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh)

Esta versão substitui a v2.0.0 porque incorpora a nomenclatura definitiva sem `-main` e o domínio público correto `studiosatweb.com.br`.

A Foundation executa numa passagem state-driven:

- admission gate de identidade GCP/hostname;
- backup forense;
- preservação de diretórios de canal antigos em backup, sem exclusão;
- LAB real do MediaMTX em portas isoladas;
- teste RTMP sintético + API + metrics + HLS;
- contas técnicas e ownership;
- CAS + nove pastas canônicas definitivas;
- `channels.json` com FQDN público de cada emissora;
- MediaMTX com exatamente nove paths definitivos;
- start se estiver inativo ou hot reload se já estiver ativo;
- validação de Nginx/BIND sem reconfigurá-los;
- classificação automática dos bloqueios seguintes.

Validação: [`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.VALIDATION.txt`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.VALIDATION.txt).

## Próximas trilhas

1. **MEDIA DATA PLANE** — conteúdo → SHA-256/ffprobe → CAS/refs/catalog → normalização → playout → NORMAL/LIVE/EMERGENCY.
2. **PUBLIC EDGE** — Nginx/HLS → sites → TLS/443 usando `*.studiosatweb.com.br`.
3. **DNS/NS2/DNSSEC** — NS1/NS2, AXFR/IXFR/NOTIFY, TSIG, DNSKEY/DS e delegação.
4. **OBSERVABILIDADE/ACEITE** — métricas, alertas, AS-BUILT e DROP comprovado do legado.

Detalhes: [`CLEANROOM-V2-MASTER.md`](CLEANROOM-V2-MASTER.md), [`STATE-20260904-CLEANROOM.md`](STATE-20260904-CLEANROOM.md) e [`EXECUTION-INDEX.md`](EXECUTION-INDEX.md).

## Documentação histórica

Os documentos `00-PRINCIPIOS.md` a `10-FASE-9-ACEITE.md`, `ARQUITETURA-ALVO.md` e o runner Foundation v2.0.0 são preservados como histórico. Quando houver divergência, **Clean-Room v2.1 + CANONICAL-NAMING.md** são a autoridade operacional.
