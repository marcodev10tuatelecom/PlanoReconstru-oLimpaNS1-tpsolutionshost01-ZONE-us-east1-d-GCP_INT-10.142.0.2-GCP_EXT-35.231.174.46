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

## Estado real atual

Após o SCRIPT 02B e a tentativa Foundation v2.2.0:

| Camada | Estado |
|---|---|
| Hostname | `ns1.tpsolutions.com.br` |
| Nginx | `active` |
| BIND | `active` |
| MediaMTX | `active` |
| MediaMTX PID observado | `36164` |
| MediaMTX `NRestarts` | `0` |
| RTMP 1935 | listening |
| HLS 8888 | listening |
| API 9997 | listening |
| FFmpeg | `0` |
| Paths configurados | `9` legados |
| Paths READY | `0` |
| Paths ONLINE | `0` |
| Publishers/readers | `0` |
| HTTPS/443 | ainda não certificado |

Os 9 paths materializados continuam sendo `radio-main`, `radio-pop`, `radio-rock`, `radio-classicas`, `radio-country`, `tvkids-main`, `tvteens-main`, `tvviva-main`, `tvmaisjovem-main`. Eles são estado transitório, não nomenclatura final.

## Foundation v2.2.0 — falha segura registrada

A v2.2.0 passou admission, backup e contrato estático, mas falhou no LAB isolado em R03:

`ERR: open /var/tmp/.../mediamtx.final.yml: permission denied`

Causa raiz: o LAB executa MediaMTX como `tpsmedia`, mas o diretório de trabalho/candidato foi criado por `root` sob `umask 027` sem traversal/read para o usuário de serviço.

A falha ocorreu **antes** de R04/R05; portanto não houve retirada dos diretórios legados nem substituição do `mediamtx.yml` de produção. O estado pós-SCRIPT-02B foi preservado.

## Autoridade operacional atual

### Foundation v2.2.1 — única versão liberada

[`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.sh`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.sh)

SHA-256:

`d3db444c4aa6d701d6e2f0feea839778b131583df5431370fe8f30aa6e858ea3`

Validação:

[`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.VALIDATION.txt`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.VALIDATION.txt)

A v2.2.1:

- mantém o admission gate exato do estado pós-SCRIPT-02B;
- corrige traversal/read do LAB para `tpsmedia`;
- prova permissões com `runuser` antes de iniciar o MediaMTX LAB;
- executa LAB real com 9 nomes finais, RTMP, bytes, HLS e decode via ffprobe;
- adiciona timeout ao decode HLS;
- preserva diretórios legados antes de retirá-los da autoridade;
- migra MediaMTX por hot reload, sem restart no caminho normal;
- exige PID e `NRestarts` invariantes;
- fortalece rollback do catálogo e dos diretórios finais criados;
- cria CAS e exatamente os 9 diretórios finais;
- mantém Nginx e BIND invariantes.

**v2.0.0, v2.1.0 e v2.2.0 estão SUPERSEDED e não devem ser executadas novamente.** Não repetir SCRIPT 02B nem usar Script 03 destrutivo com `rm -rf` de canais.

## Próximas trilhas

1. **MEDIA DATA PLANE** — localizar fonte de conteúdo autoritativa → ffprobe/SHA-256 → CAS/refs/catalog → normalização → playout → NORMAL/LIVE/EMERGENCY.
2. **PUBLIC EDGE** — Nginx/HLS → sites → TLS/443 em `studiosatweb.com.br`.
3. **DNS/NS2/DNSSEC** — NS1/NS2, AXFR/IXFR/NOTIFY, TSIG, DNSKEY/DS e delegação.
4. **OBSERVABILIDADE/ACEITE** — métricas, alertas, AS-BUILT e DROP comprovado do legado.

Detalhes: [`CLEANROOM-V2-MASTER.md`](CLEANROOM-V2-MASTER.md), [`STATE-20260904-CLEANROOM.md`](STATE-20260904-CLEANROOM.md), [`EXECUTION-INDEX.md`](EXECUTION-INDEX.md) e [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).
