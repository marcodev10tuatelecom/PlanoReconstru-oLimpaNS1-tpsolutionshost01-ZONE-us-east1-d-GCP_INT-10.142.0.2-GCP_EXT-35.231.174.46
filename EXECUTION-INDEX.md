# Índice de Execução — NS1 Clean-Room

Este arquivo evita desvio de foco e execução acidental de versões antigas.

## Estado dos artefatos

| Ordem | Artefato | Estado | Autoridade |
|---|---|---|---|
| 00 | Fase 0 agressiva de isolamento executada externamente | EXECUTADA | histórica; não repetir |
| 01 | SCRIPT 02B externo/Grok | EXECUTADO | deixou MediaMTX `active` com 9 paths legados ociosos |
| A | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh` | **LIBERADO** | **autoridade atual** |
| A-old | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh` | SUPERSEDED / BLOQUEADO | não executar |
| A-old | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh` | SUPERSEDED / BLOQUEADO | não executar |
| B | MEDIA DATA PLANE | A GERAR APÓS PASS DO v2.2 E LOCALIZAÇÃO DA FONTE DE CONTEÚDO | não existe executável liberado ainda |
| C | PUBLIC EDGE | PENDENTE | não existe executável liberado ainda |
| D | DNS/NS2/DNSSEC | PENDENTE | não existe executável liberado ainda |
| E | OBSERVABILIDADE/ACEITE | PENDENTE | não existe executável liberado ainda |

## Estado de entrada exigido pelo Runner A v2.2

O v2.2 aceita apenas:

1. exatamente os 9 paths legados do SCRIPT 02B, todos ociosos; ou
2. exatamente os 9 paths finais, todos ociosos.

Estado pós-SCRIPT-02B comprovado pelo operador:

- MediaMTX `active`;
- 9 paths configurados;
- 0 READY;
- 0 ONLINE;
- 0 source/publisher;
- 0 readers;
- FFmpeg 0.

## Nomenclatura obrigatória

Autoridade: [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

Emissoras usam `studiosatweb.com.br`; `tpsolutions.com.br` permanece domínio de infraestrutura/hosting.

## Regras de execução

- Não executar novamente SCRIPT 02B.
- Não executar Script 03 destrutivo com `rm -rf` de canais.
- Não executar Foundation v2.0.0 ou v2.1.0.
- Não reiniciar MediaMTX no caminho normal do v2.2; a migração usa hot reload.
- PID e `NRestarts` do MediaMTX devem permanecer invariantes.
- Antes da mutação, o v2.2 executa LAB real com os nomes finais, RTMP sintético, bytes, HLS e decode via ffprobe.
- Em falha pós-mudança, restaurar configuração MediaMTX e diretórios retirados da autoridade.

## Próxima execução

Executar somente:

`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh`

SHA-256 esperado:

`1520afb3a5df9919c3fcac20be6fa882e68a9790d7ca8f822b114e98df65eb08`

PASS esperado:

`RESULT=PASS_FOUNDATION_R00_R07_V2_2`
