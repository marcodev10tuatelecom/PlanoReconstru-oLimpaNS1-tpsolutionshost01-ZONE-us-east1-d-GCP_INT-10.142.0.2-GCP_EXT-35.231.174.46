# Plano de Reconstrução Limpa e Completa – NS1

**Host:** `tpsolutionshost01` / `ns1.tpsolutions.com.br`  
**Zona:** `us-east1-d`  
**IP Interno:** `10.142.0.2`  
**IP Externo:** `35.231.174.46`  
**Projeto GCP:** `project-5fa502b6-8909-4e17-a40`  
**Data de criação:** 2026-09-04  
**Autoridade:** Tech Pro Solutions Inc. / StudioSat

---

## Objetivo

Reconstruir de forma **limpa, determinística e sem herança de problemas anteriores** a plataforma completa de:

- 5 emissoras de rádio (radio-main, radio-pop, radio-rock, radio-classicas, radio-country)
- 4 emissoras de TV (tvkids-main, tvteens-main, tvviva-main, tvmaisjovem-main)
- Entrega HLS + sites públicos
- HTTPS funcional
- DNS autoridade

**Princípio fundamental:** Não remendar. Reconstruir.

---

## Estado Atual (Raio-X 2026-09-04)

| Camada                    | Estado          | Severidade |
|---------------------------|-----------------|------------|
| MediaMTX                  | Ativo           | Baixa      |
| Paths ativos              | 0/9             | Crítica    |
| Publishers FFmpeg         | 0               | Crítica    |
| Repositório CAS           | Ausente         | Crítica    |
| Canais lógicos            | DIR=False       | Crítica    |
| HTTPS (443)               | Fora            | Alta       |
| Nginx (80)                | Ativo           | Média      |
| DNS BIND                  | Ativo (parcial) | Média-Alta |
| Units de playout          | Inexistentes    | Crítica    |

---

## Fases da Reconstrução

| Fase | Nome                              | Status     |
|------|-----------------------------------|------------|
| 0    | Preparação e Congelamento         | Pendente   |
| 1    | Limpeza Controlada                | Pendente   |
| 2    | Repositório Canônico              | Pendente   |
| 3    | MediaMTX Canônico                 | Pendente   |
| 4    | Playout 24×7 (9 emissoras)        | Pendente   |
| 5    | Nginx + HLS + Sites               | Pendente   |
| 6    | HTTPS / TLS                       | Pendente   |
| 7    | DNS e Validação Pública           | Pendente   |
| 8    | Observabilidade e Hardening       | Pendente   |
| 9    | Aceite Final                      | Pendente   |

---

## Documentos do Plano

- [`00-PRINCIPIOS.md`](00-PRINCIPIOS.md) – Princípios de reconstrução
- [`01-FASE-0-PREPARACAO.md`](01-FASE-0-PREPARACAO.md)
- [`02-FASE-1-LIMPEZA.md`](02-FASE-1-LIMPEZA.md)
- [`03-FASE-2-REPOSITORIO.md`](03-FASE-2-REPOSITORIO.md)
- [`04-FASE-3-MEDIAMTX.md`](04-FASE-3-MEDIAMTX.md)
- [`05-FASE-4-PLAYOUT.md`](05-FASE-4-PLAYOUT.md)
- [`06-FASE-5-NGINX-HLS.md`](06-FASE-5-NGINX-HLS.md)
- [`07-FASE-6-HTTPS.md`](07-FASE-6-HTTPS.md)
- [`08-FASE-7-DNS.md`](08-FASE-7-DNS.md)
- [`09-FASE-8-OBSERVABILIDADE.md`](09-FASE-8-OBSERVABILIDADE.md)
- [`10-FASE-9-ACEITE.md`](10-FASE-9-ACEITE.md)
- [`ARQUITETURA-ALVO.md`](ARQUITETURA-ALVO.md)

---

## Regras de Ouro

1. Nenhuma fase avança sem validação da fase anterior.
2. Nenhum script de recovery antigo será reutilizado.
3. Toda mudança é registrada e reversível.
4. Conteúdo só entra por ingestão controlada.
5. Playout é sempre 1 processo FFmpeg por emissora (conexão RTMP persistente).

---

**Próximo passo:** Executar a **Fase 0**.
