# Clean-Room v2.1 — Plano Mestre de Execução NS1

## Estado de entrada

- Recurso GCP preservado: `tpsolutionshost01`
- Função lógica: `NS1`
- FQDN: `ns1.tpsolutions.com.br`
- IP privado: `10.142.0.2`
- IP público: `35.231.174.46`
- Legado `/srv/tpsmedia` já isolado em árvore `tpsmedia-legacy-*`
- Nova `/srv/tpsmedia` criada
- Nginx: ativo
- BIND: ativo
- MediaMTX: inativo no último RX pós-mudança
- FFmpeg: 0
- paths runtime: 0

O rótulo `NS3` emitido pelo coletor pós-mudança é incorreto. Este projeto trata esta máquina como **NS1 clean-room**.

## Contrato definitivo de nomenclatura

### Domínios

- `tpsolutions.com.br`: infraestrutura, hosting e nomes de servidores.
- `studiosatweb.com.br`: superfície pública das emissoras.

### IDs internos

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

## Regra operacional

O projeto usa runners **state-driven**:

1. analisar estado real;
2. testar artefatos e configuração em LAB quando aplicável;
3. executar automaticamente apenas mudanças determinísticas;
4. validar imediatamente cada mudança;
5. rollback quando o pós-estado viola o contrato;
6. parar somente em `FATAL=` ou `BLOCKER=` que dependa de conteúdo, NS2, Registro.br ou outro sistema externo.

Não recriar VM, boot disk, IP ou recurso GCP.

## Runner A — FOUNDATION R00–R07

Autoridade atual: `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.1.0.sh`.

A v2.0.0 está **SUPERSEDED** por conter os nomes anteriores `*-main` / `radio-*`.

A v2.1.0 executa numa única passagem:

- identidade cloud/host fail-closed;
- backup forense de configuração;
- preservação de canais legados em backup, sem `rm -rf`;
- construção do candidato MediaMTX com exatamente nove IDs definitivos;
- LAB com o binário real do MediaMTX em portas alternativas;
- publish sintético em `radiopop` e validação API + metrics + HLS;
- contas técnicas e ownership;
- CAS preparado desde a fundação;
- nove pastas canônicas;
- registry `channels.json` com domínio público StudioSat;
- start do MediaMTX se inativo ou hot reload se ativo;
- invariantes de Nginx/BIND;
- classificação automática dos próximos bloqueios.

O Runner A não reinicia Nginx/BIND, não altera firewall, não emite certificados e não modifica DNS.

## Runner B — MEDIA DATA PLANE

Entrará somente com fonte de conteúdo autoritativa identificada.

Fluxo obrigatório:

`incoming → ffprobe/validação → SHA-256 → CAS → refs → catalog → normalização técnica → playout`.

O playout deve preservar uma única autoridade por canal e suportar NORMAL/LIVE/EMERGENCY sem publishers concorrentes.

## Runner C — PUBLIC EDGE

- Nginx/HLS;
- sites das nove emissoras;
- hostnames públicos em `studiosatweb.com.br`;
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
- source ID / bytes;
- CPU/RAM/disk;
- DNS/DNSSEC probes;
- AS-BUILT;
- DROP comprovado do legado.

## Critério de velocidade

Não há parada entre microetapas quando o runner consegue provar e executar com segurança. O objetivo é concluir blocos inteiros de engenharia, não pedir confirmação para cada comando local determinístico.
