# Nomenclatura Canônica Definitiva — TPS / StudioSat

## Fronteira de domínios

- **Infraestrutura / hosting / nomes dos servidores:** `tpsolutions.com.br`
- **Emissoras públicas de rádio e TV:** `studiosatweb.com.br`
- Hostname deste nó: `ns1.tpsolutions.com.br`

Nunca publicar as emissoras sob `*.tpsolutions.com.br` salvo decisão futura explícita de produto. O domínio das emissoras é `studiosatweb.com.br`.

## IDs internos, pastas, paths e FQDN públicos

| Tipo | ID interno canônico | Repositório | Path MediaMTX | FQDN público |
|---|---|---|---|---|
| Rádio principal | `radioprincipal` | `/srv/tpsmedia/repository/channels/radioprincipal/` | `radioprincipal` | `radio.studiosatweb.com.br` |
| Rádio POP | `radiopop` | `/srv/tpsmedia/repository/channels/radiopop/` | `radiopop` | `radiopop.studiosatweb.com.br` |
| Rádio ROCK | `radiorock` | `/srv/tpsmedia/repository/channels/radiorock/` | `radiorock` | `radiorock.studiosatweb.com.br` |
| Rádio Clássicas | `radioclassicas` | `/srv/tpsmedia/repository/channels/radioclassicas/` | `radioclassicas` | `radioclassicas.studiosatweb.com.br` |
| Rádio Country | `radiocountry` | `/srv/tpsmedia/repository/channels/radiocountry/` | `radiocountry` | `radiocountry.studiosatweb.com.br` |
| TV Kids | `tvkids` | `/srv/tpsmedia/repository/channels/tvkids/` | `tvkids` | `tvkids.studiosatweb.com.br` |
| TV Teens | `tvteens` | `/srv/tpsmedia/repository/channels/tvteens/` | `tvteens` | `tvteens.studiosatweb.com.br` |
| TV Viva | `tvviva` | `/srv/tpsmedia/repository/channels/tvviva/` | `tvviva` | `tvviva.studiosatweb.com.br` |
| TV Mais Jovem | `tvmaisjovem` | `/srv/tpsmedia/repository/channels/tvmaisjovem/` | `tvmaisjovem` | `tvmaisjovem.studiosatweb.com.br` |

## Regra de autoridade

`1 emissora = 1 ID interno = 1 pasta canônica = 1 path MediaMTX = 1 identidade pública`.

Variantes técnicas como bitrate, ABR, LIVE, emergency, clean/remux ou ingest são funções internas e não criam outra identidade pública da emissora.

## Nomes proibidos como nova autoridade

Não criar ou reintroduzir:

- `radio-main`, `radio-pop`, `radio-rock`, `radio-classicas`, `radio-country`;
- `tvkids-main`, `tvteens-main`, `tvviva-main`, `tvmaisjovem-main`;
- qualquer `-32`, `-64`, `-clean`, `-old`, `-new`, `-backup`, `-test`;
- `tv-main`, `tv2-main`, `tv-crista-*`, `tv-jovem-*`, `radiotv-main`.

Se algum nome antigo contiver dados, ele deve ser preservado em backup/evidência e migrado deliberadamente; nunca executado em paralelo como autoridade.
