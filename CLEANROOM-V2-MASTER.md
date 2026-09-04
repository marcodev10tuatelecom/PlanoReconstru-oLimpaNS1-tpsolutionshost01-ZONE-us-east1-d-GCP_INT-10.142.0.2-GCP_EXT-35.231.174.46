# Clean-Room v2.2 — Plano Mestre de Execução NS1

## Estado de entrada atual

- Recurso GCP preservado: `tpsolutionshost01`
- Função lógica: `NS1`
- FQDN: `ns1.tpsolutions.com.br`
- IP privado: `10.142.0.2`
- IP público: `35.231.174.46`
- Nginx: `active`
- BIND: `active`
- MediaMTX: `active` após SCRIPT 02B
- FFmpeg: `0`
- MediaMTX: 9 paths configurados, todos `ready=false`, `online=false`, `source=null`, sem readers

O rótulo `NS3` emitido por um coletor anterior é incorreto. Este projeto trata a máquina como **NS1 clean-room**.

## Contrato definitivo de nomenclatura

### Domínios

- `tpsolutions.com.br`: infraestrutura, hosting e nomes de servidores.
- `studiosatweb.com.br`: superfície pública das emissoras.

### IDs internos finais

1. `radioprincipal`
2. `radiopop`
3. `radiorock`
4. `radioclassicas`
5. `radiocountry`
6. `tvkids`
7. `tvteens`
8. `tvviva`
9. `tvmaisjovem`

Não usar `-main` na nova arquitetura. Consulte [`CANONICAL-NAMING.md`](CANONICAL-NAMING.md).

## Estado transitório atual do MediaMTX

O SCRIPT 02B deixou configurados:

`radio-main`, `radio-pop`, `radio-rock`, `radio-classicas`, `radio-country`, `tvkids-main`, `tvteens-main`, `tvviva-main`, `tvmaisjovem-main`.

Eles são permitidos apenas como **estado de entrada de migração**, nunca como autoridade final.

## Regra operacional

O projeto usa runners **state-driven**:

1. analisar o estado real;
2. testar em LAB o candidato exato;
3. executar automaticamente mudanças locais determinísticas;
4. validar imediatamente cada mudança;
5. rollback integral quando o pós-estado viola o contrato;
6. parar somente em `FATAL=` ou `BLOCKER=` externo.

Não recriar VM, boot disk, IP ou recurso GCP.

## Runner A — FOUNDATION R00–R07

Autoridade atual: `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.2.0.sh`.

### Versões bloqueadas

- v2.0.0: SUPERSEDED por nomenclatura antiga.
- v2.1.0: SUPERSEDED antes de execução devido ao estado pós-SCRIPT-02B e a defeitos de rollback identificados na revisão.

### Contrato do v2.2

- aceita somente os 9 paths legados exatos do SCRIPT 02B ou os 9 finais;
- exige todos os paths ociosos e FFmpeg zero;
- faz backup de `/etc/tpsmedia`, Nginx, BIND, systemd TPS e árvore `/srv/tpsmedia`;
- executa LAB com binário real do MediaMTX em portas alternativas;
- exige no LAB: 9 paths finais, metrics, publish RTMP `radiopop`, `ready=true`, bytes > 0, HLS e decode de áudio via ffprobe;
- inventaria e preserva diretórios legados antes de retirá-los da autoridade;
- aplica MediaMTX por hot reload, sem restart no caminho normal;
- exige `MainPID` e `NRestarts` invariantes;
- restaura configuração anterior e diretórios retirados em rollback;
- cria contas técnicas, CAS e nove diretórios finais;
- grava `channels.json` com domínio StudioSat;
- não altera Nginx/BIND, apenas valida invariantes.

PASS esperado: `RESULT=PASS_FOUNDATION_R00_R07_V2_2`.

## Runner B — MEDIA DATA PLANE

Entrará após PASS do Runner A e identificação da fonte de conteúdo autoritativa.

Fluxo obrigatório:

`fonte autoritativa → ffprobe/validação → SHA-256 → CAS → refs → catalog → normalização técnica → playout`.

Nada de restaurar cegamente árvore antiga. O playout deve ter uma única autoridade por canal e suportar NORMAL/LIVE/EMERGENCY sem publishers concorrentes.

## Runner C — PUBLIC EDGE

- Nginx/HLS;
- sites das nove emissoras;
- hostnames em `studiosatweb.com.br`;
- TLS/SAN/chain;
- 443;
- nenhuma emissão automática de certificado antes de prova de DNS/ownership.

## Runner D — DNS / NS2 / DNSSEC

- autoridade NS1;
- NS2 real;
- AXFR/IXFR/NOTIFY + TSIG;
- conjunto NS filho/pai coerente;
- DNSKEY/DS calculados e comparados;
- atualização parental somente após validação dos dois servidores.

## Runner E — OBSERVABILIDADE + ACEITE

- MediaMTX metrics;
- publisher collision;
- HLS freshness;
- source/bytes;
- CPU/RAM/disk;
- DNS/DNSSEC probes;
- AS-BUILT;
- DROP comprovado do legado.

## Critério de velocidade

Não há parada entre microetapas quando o runner consegue provar e executar com segurança. O objetivo é concluir blocos inteiros de engenharia, não pedir confirmação para cada comando local determinístico.
