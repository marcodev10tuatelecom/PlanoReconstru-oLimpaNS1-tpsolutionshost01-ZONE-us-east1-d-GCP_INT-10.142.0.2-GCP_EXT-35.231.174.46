# Plano de Reconstrução Limpa e Completa — NS1

**Cloud resource:** `tpsolutionshost01`  
**Função TPS:** `NS1`  
**FQDN:** `ns1.tpsolutions.com.br`  
**Zona:** `us-east1-d`  
**IP Interno:** `10.142.0.2`  
**IP Externo:** `35.231.174.46`  
**Data-base:** 2026-09-04

## Decisão arquitetural

**Não remendar. Reconstruir in-place preservando a VM GCP.** O legado permanece fonte forense; a nova `/srv/tpsmedia` é a autoridade clean-room.

## Fronteira de domínios

- Infraestrutura / hosting / servidores: `tpsolutions.com.br`
- Emissoras de rádio e TV: `studiosatweb.com.br`
- Este servidor: `ns1.tpsolutions.com.br`

A nomenclatura definitiva está em [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).

## 9 IDs canônicos definitivos

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

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

Não criar novamente `-main`, `-32`, `-64`, `-clean`, `-old`, `-new`, `tv2-*`, `tv-crista-*`, `tv-jovem-*` ou `radiotv-main` como autoridade.

## Estado real pós-SCRIPT-02B

| Camada | Estado |
|---|---|
| Hostname | `ns1.tpsolutions.com.br` |
| Nginx | `active` |
| BIND | `active` |
| MediaMTX | `active` |
| RTMP 1935 | listening |
| HLS 8888 | listening |
| API 9997 | listening |
| FFmpeg | `0` |
| Paths configurados | `9` |
| Paths READY | `0` |
| Paths ONLINE | `0` |
| Publishers/readers | `0` |
| HTTPS/443 | ainda não certificado |

Os 9 paths atualmente materializados pela API são os nomes legados do SCRIPT 02B: `radio-main`, `radio-pop`, `radio-rock`, `radio-classicas`, `radio-country`, `tvkids-main`, `tvteens-main`, `tvviva-main`, `tvmaisjovem-main`. Eles são estado transitório, não nomenclatura final.

## Autoridade operacional atual

### Foundation v2.2.0 — única versão liberada

[`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh)

SHA-256:

`1520afb3a5df9919c3fcac20be6fa882e68a9790d7ca8f822b114e98df65eb08`

A v2.2 foi criada especificamente para o estado pós-SCRIPT-02B. Ela:

- admite somente o conjunto exato de 9 paths legados ou os 9 finais;
- exige todos os paths ociosos e FFmpeg zero;
- faz backup forense antes da mutação;
- executa LAB real com MediaMTX em portas isoladas;
- exige 9 nomes finais, RTMP `radiopop` READY, bytes > 0, HLS e decode via ffprobe;
- preserva diretórios legados antes de retirá-los da autoridade;
- migra MediaMTX por hot reload, sem `systemctl restart` no caminho normal;
- exige PID e `NRestarts` invariantes;
- implementa rollback de configuração MediaMTX e diretórios retirados;
- cria CAS e exatamente os 9 diretórios finais;
- mantém Nginx e BIND invariantes.

Validação: [`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.VALIDATION.txt`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.VALIDATION.txt).

**v2.0.0 e v2.1.0 estão SUPERSEDED e não devem ser executadas.** Não executar novamente o SCRIPT 02B nem o Script 03 destrutivo com `rm -rf` de canais.

## Próximas trilhas

1. **MEDIA DATA PLANE** — localizar fonte de conteúdo autoritativa → ffprobe/SHA-256 → CAS/refs/catalog → normalização → playout → NORMAL/LIVE/EMERGENCY.
2. **PUBLIC EDGE** — Nginx/HLS → sites → TLS/443 em `studiosatweb.com.br`.
3. **DNS/NS2/DNSSEC** — NS1/NS2, AXFR/IXFR/NOTIFY, TSIG, DNSKEY/DS e delegação.
4. **OBSERVABILIDADE/ACEITE** — métricas, alertas, AS-BUILT e DROP comprovado do legado.

Detalhes: [`CLEANROOM-V2-MASTER.md`](CLEANROOM-V2-MASTER.md), [`STATE-20260904-CLEANROOM.md`](STATE-20260904-CLEANROOM.md), [`EXECUTION-INDEX.md`](EXECUTION-INDEX.md) e [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).

## Documentação histórica

Os documentos antigos e runners v2.0/v2.1 permanecem apenas como histórico. Quando houver divergência, **Foundation v2.2 + CANONICAL-NAMING.md + STATE-20260904-CLEANROOM.md** são a autoridade operacional.
