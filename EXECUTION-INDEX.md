# Índice de Execução — NS1 Clean-Room

Este arquivo evita desvio de foco e execução acidental de versões antigas.

## Estado dos artefatos

| Ordem | Artefato | Estado | Autoridade |
|---|---|---|---|
| 00 | Fase 0 agressiva de isolamento executada externamente | EXECUTADA / evidência do operador | histórica; não repetir cegamente |
| 01 | Padronização externa/Grok para nomes sem `-main` | INFORMADA COMO EXECUTADA | será certificada pelo Runner A v2.1 |
| A | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh` | **LIBERADO** | autoridade atual |
| A-old | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh` | SUPERSEDED | não executar |
| B | MEDIA DATA PLANE | A GERAR APÓS PASS DO RUNNER A E LOCALIZAÇÃO DA FONTE DE CONTEÚDO | não existe executável liberado ainda |
| C | PUBLIC EDGE | PENDENTE | não existe executável liberado ainda |
| D | DNS/NS2/DNSSEC | PENDENTE | não existe executável liberado ainda |
| E | OBSERVABILIDADE/ACEITE | PENDENTE | não existe executável liberado ainda |

## Regra

Nenhum script futuro será salvo como “pronto” antes de passar, no mínimo, por sintaxe, análise estática e testes/mocks aplicáveis. Scripts que dependem do runtime real devem conter LAB/precheck fail-closed antes da mutação.

## Nomenclatura obrigatória

A autoridade é [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md):

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

Emissoras usam `studiosatweb.com.br`; `tpsolutions.com.br` permanece domínio de infraestrutura/hosting.

## Próxima execução

Executar apenas `TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh`. O PASS esperado é `RESULT=PASS_FOUNDATION_R00_R07_V2_1`.
