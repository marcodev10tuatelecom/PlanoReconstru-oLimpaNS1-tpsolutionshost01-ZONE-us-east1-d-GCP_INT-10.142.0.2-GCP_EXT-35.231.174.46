# Plano de Reconstrução Limpa e Completa – NS1

**Cloud resource:** `tpsolutionshost01`  
**Função TPS:** `NS1`  
**FQDN:** `ns1.tpsolutions.com.br`  
**Zona:** `us-east1-d`  
**IP Interno:** `10.142.0.2`  
**IP Externo:** `35.231.174.46`  
**Data-base:** 2026-09-04  

## Decisão arquitetural

**Não remendar. Reconstruir in-place preservando a VM GCP.** A árvore histórica `/srv/tpsmedia` já foi isolada sob `/srv/tpsmedia-legacy-*`; o legado passa a ser fonte forense, não autoridade operacional.

## Estado pós-mudança confirmado pelo operador

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

O coletor usado após a mudança imprimiu `NS3`; esse rótulo é incorreto para este projeto. Esta máquina é o **NS1 clean-room**.

## Execução v2

A reconstrução passa a ser **state-driven**: cada runner analisa, executa todas as mudanças locais determinísticas, valida e faz rollback quando necessário. Não haverá parada entre microetapas quando o estado puder ser comprovado automaticamente.

### Trilha A — FOUNDATION R00–R07

Arquivo: [`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh`](scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh)

- identidade GCP/hostname fail-closed;
- backup forense;
- contas técnicas e ownership;
- repositório CAS-ready + 9 canais;
- MediaMTX limpo com exatamente 9 paths;
- teste real do binário em portas LAB;
- publish sintético + HLS no LAB;
- start do MediaMTX se inativo, ou hot reload se já ativo;
- Nginx/BIND preservados e validados;
- classificação automática dos bloqueios externos.

### Próximas trilhas

1. **MEDIA DATA PLANE** — conteúdo → SHA-256/ffprobe → CAS/refs/catalog → playout persistente → NORMAL/LIVE/EMERGENCY.
2. **PUBLIC EDGE** — Nginx/HLS → TLS/443 → sites das emissoras.
3. **DNS/NS2/DNSSEC** — NS2 real, AXFR/IXFR/NOTIFY, TSIG, DNSKEY/DS parental.
4. **OBSERVABILIDADE/ACEITE** — métricas, alertas, AS-BUILT e DROP comprovado do legado.

Detalhes: [`CLEANROOM-V2-MASTER.md`](CLEANROOM-V2-MASTER.md) e [`STATE-20260904-CLEANROOM.md`](STATE-20260904-CLEANROOM.md).

## 9 IDs canônicos

`radio-main`, `radio-pop`, `radio-rock`, `radio-classicas`, `radio-country`, `tvkids-main`, `tvteens-main`, `tvviva-main`, `tvmaisjovem-main`.

Não criar `-32`, `-64`, `-clean`, `-old`, `-new`, `tv2-*`, `tv-crista-*` ou `tv-jovem-*`.

## Documentação histórica

Os documentos `00-PRINCIPIOS.md` a `10-FASE-9-ACEITE.md` e `ARQUITETURA-ALVO.md` ficam preservados como **Plano v1**. Quando houver divergência, o **Clean-Room v2** é a autoridade operacional.
