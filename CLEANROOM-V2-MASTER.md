# Clean-Room v2 — Plano Mestre de Execução NS1

## Estado de entrada confirmado em 2026-09-04

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
- paths ativos: 0
- HTTPS/443: não comprovado/ausente no RX

> O rótulo `NS3` exibido pelo coletor usado após a mudança está incorreto para este projeto. A máquina é tratada como **NS1 clean-room**.

## Regra operacional

O projeto deixa de ser uma sequência de comandos manuais e passa a usar **runners state-driven**:

1. analisar o estado real;
2. executar automaticamente apenas mudanças determinísticas;
3. validar imediatamente cada mudança;
4. rollback automático quando o estado pós-mudança não satisfaz o contrato;
5. parar somente em dependência externa ou dado ausente.

Não recriar a VM, boot disk, IP ou recurso GCP.

## Trilhas de execução

### Runner A — FOUNDATION (R00–R07)

Arquivo: `scripts/TPS-NS1-CLEANROOM-MASTER-FOUNDATION-v2.0.0.sh`

Executa numa única passagem:

- identidade cloud/host fail-closed;
- backup forense de configuração;
- contas técnicas e ownership base;
- repositório canônico com CAS preparado;
- nove canais canônicos;
- MediaMTX clean-room com somente 9 paths;
- teste do YAML com PyYAML;
- teste do binário real em portas LAB;
- publish sintético + HLS no LAB;
- start do MediaMTX se estiver inativo ou hot reload se estiver ativo;
- valida Nginx/BIND e classifica bloqueios restantes.

Não reinicia Nginx, BIND ou MediaMTX no caminho normal.

### Runner B — MEDIA DATA PLANE

Somente após haver fonte de conteúdo autoritativa.

- restauração/ingest controlado;
- SHA-256, ffprobe, quarantine;
- CAS + refs + catalog;
- normalização técnica quando necessária;
- playout persistente por emissora;
- validação READY/ONLINE/bytes/HLS;
- NORMAL/LIVE/EMERGENCY sem publishers concorrentes.

### Runner C — PUBLIC EDGE

- Nginx/HLS;
- TLS/SAN/chain;
- 443;
- superfícies públicas por emissora;
- nenhuma emissão automática de certificado sem prova de DNS/ownership.

### Runner D — DNS/NS2/DNSSEC

- autoridade NS1;
- NS2 real;
- AXFR/IXFR/NOTIFY + TSIG;
- NS set filho/pai coerente;
- DNSKEY/DS calculados e comparados;
- atualização parental somente após validação dos dois servidores.

### Runner E — OBSERVABILIDADE + ACEITE

- MediaMTX metrics;
- publisher collision;
- HLS freshness;
- source ID / bytes;
- CPU/RAM/disk;
- DNS/DNSSEC probes;
- AS-BUILT final e DROP comprovado do legado.

## Matriz canônica das emissoras

1. `radio-main`
2. `radio-pop`
3. `radio-rock`
4. `radio-classicas`
5. `radio-country`
6. `tvkids-main`
7. `tvteens-main`
8. `tvviva-main`
9. `tvmaisjovem-main`

Não criar paths `-32`, `-64`, `-clean`, `-old`, `-new`, `tv2-*`, `tv-crista-*` ou `tv-jovem-*`.

## Critério de velocidade

Não há parada entre microetapas quando o runner consegue provar e executar com segurança. Um runner atravessa todos os gates locais consecutivamente. A execução para apenas em `FATAL=` ou em `BLOCKER=` que dependa de conteúdo, NS2, Registro.br ou outro sistema externo.
