# Evidência pós-SCRIPT-02B — 2026-09-04

## Fonte

Saída integral informada pelo operador após execução do `TPS CLEAN REBUILD - SCRIPT 02B`.

## Resultado comprovado

- Hostname: `ns1.tpsolutions.com.br`
- `/etc/hosts`: `10.142.0.2 ns1.tpsolutions.com.br ns1`
- MediaMTX: `active`
- Porta 1935: escutando
- Porta 8888: escutando
- Porta 9997: escutando
- FFmpeg: nenhum publisher comprovado

## API `/v3/paths/list`

`itemCount=9`, `pageCount=1`.

Paths materializados:

1. `radio-classicas`
2. `radio-country`
3. `radio-main`
4. `radio-pop`
5. `radio-rock`
6. `tvkids-main`
7. `tvmaisjovem-main`
8. `tvteens-main`
9. `tvviva-main`

Para todos os nove:

- `ready=false`
- `available=false`
- `online=false`
- `source=null`
- `tracks=[]`
- `readers=[]`
- `inboundBytes=0`
- `outboundBytes=0`
- `bytesReceived=0`
- `bytesSent=0`

## Interpretação

Neste runtime, paths explicitamente configurados aparecem na API mesmo sem publisher. Portanto o estado correto é:

`CONFIGURED_PATHS=9 / READY=0 / ONLINE=0 / PUBLISHERS=0 / READERS=0`.

Os nove nomes acima são transitórios e legados. A autoridade final continua sendo:

`radioprincipal`, `radiopop`, `radiorock`, `radioclassicas`, `radiocountry`, `tvkids`, `tvteens`, `tvviva`, `tvmaisjovem`.

## Implicação para a próxima mudança

O SCRIPT 02B já executou restart do MediaMTX. A próxima migração deve ocorrer por hot reload, sem novo restart no caminho normal, e deve exigir PID e `NRestarts` invariantes.
