# Índice de Execução — NS1 Clean-Room

Este arquivo evita desvio de foco e execução acidental de versões antigas.

## Estado dos artefatos

| Ordem | Artefato | Estado | Autoridade |
|---|---|---|---|
| 00 | Fase 0 agressiva de isolamento executada externamente | EXECUTADA | histórica; não repetir |
| 01 | SCRIPT 02B externo/Grok | EXECUTADO | deixou MediaMTX `active` com 9 paths legados ociosos |
| A | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.sh` | **LIBERADO** | **autoridade atual** |
| A-old | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh` | FAIL SAFE R03 / SUPERSEDED | não executar novamente |
| A-old | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh` | SUPERSEDED / BLOQUEADO | não executar |
| A-old | `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh` | SUPERSEDED / BLOQUEADO | não executar |
| B | MEDIA DATA PLANE | A GERAR APÓS PASS DO v2.2.1 E LOCALIZAÇÃO DA FONTE DE CONTEÚDO | não existe executável liberado ainda |
| C | PUBLIC EDGE | PENDENTE | não existe executável liberado ainda |
| D | DNS/NS2/DNSSEC | PENDENTE | não existe executável liberado ainda |
| E | OBSERVABILIDADE/ACEITE | PENDENTE | não existe executável liberado ainda |

## Estado de entrada atual

A execução do v2.2.0 falhou de forma segura no LAB isolado por permissão de leitura do candidato YAML pelo usuário `tpsmedia`.

Estado de produção permaneceu no estado pós-SCRIPT-02B:

- MediaMTX `active`;
- PID observado: `36164`;
- `NRestarts=0`;
- 9 paths configurados legados;
- 0 READY;
- 0 ONLINE;
- 0 source/publisher;
- 0 readers;
- FFmpeg 0.

Nenhuma migração de path ou repositório ocorreu antes da falha.

## Nomenclatura obrigatória

Autoridade: [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

Emissoras usam `studiosatweb.com.br`; `tpsolutions.com.br` permanece domínio de infraestrutura/hosting.

## Correções v2.2.1

- `WORK` recebe grupo primário real de `tpsmedia` e modo `0750`;
- candidato MediaMTX recebe `root:<grupo-tpsmedia>` e modo `0640`;
- antes do LAB, `runuser -u tpsmedia` prova traversal/read do candidato;
- `ffprobe` do LAB recebe timeout de 15 s;
- rollback passa a restaurar/remover `channels.json` conforme o pré-estado;
- diretórios finais criados pelo runner são removidos no rollback apenas se vazios; dados não vazios são preservados;
- continuam proibidos `systemctl restart`, alteração de firewall, pacote ou DNS no caminho normal.

## Regras de execução

- Não executar novamente SCRIPT 02B.
- Não executar Script 03 destrutivo com `rm -rf` de canais.
- Não executar Foundation v2.0.0, v2.1.0 ou v2.2.0.
- O v2.2.1 executa LAB real antes da primeira mutação de produção.
- Migração de produção usa hot reload.
- PID e `NRestarts` do MediaMTX devem permanecer invariantes.
- Em falha pós-mudança, restaurar configuração MediaMTX e diretórios retirados da autoridade.

## Próxima execução

Executar somente:

`scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.1.sh`

SHA-256 esperado:

`d3db444c4aa6d701d6e2f0feea839778b131583df5431370fe8f30aa6e858ea3`

PASS esperado:

`RESULT=PASS_FOUNDATION_R00_R07_V2_2_1`
