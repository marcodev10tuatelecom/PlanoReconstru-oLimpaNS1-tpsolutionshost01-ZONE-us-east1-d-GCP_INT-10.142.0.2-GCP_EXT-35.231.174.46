# 00 – Princípios de Reconstrução

## 1. Arquitetura de Autoridade

Toda a plataforma deve ter **uma única fonte de verdade** por camada:

| Camada              | Autoridade Canônica                          |
|---------------------|----------------------------------------------|
| Conteúdo            | `/srv/tpsmedia/repository/`                  |
| Roteamento de mídia | MediaMTX (`/etc/tpsmedia/mediamtx/`)         |
| Playout             | systemd units `tps-<canal>-playout.service`  |
| Entrega HTTP/HLS   | Nginx (`/etc/nginx/`)                        |
| TLS                 | Certbot + Nginx                              |
| DNS                 | BIND9 (`/etc/bind/`)                         |

## 2. Modelo de Playout (obrigatório)

```
Arquivos MP3/MP4
      ↓
Playlist (ffconcat)
      ↓
1× FFmpeg (processo permanente)
      ↓
RTMP → MediaMTX (path)
      ↓
HLS (MediaMTX) → Nginx → Público
```

- A conexão RTMP **nunca** é derrubada na troca de faixa.
- Um único processo FFmpeg por emissora.
- Restart automático via systemd.

## 3. Repositório

Estrutura mínima e limpa:

```
/srv/tpsmedia/repository/
├── channels/
│   ├── radio-main/
│   │   ├── ready/          # arquivos prontos para playout
│   │   ├── playlists/
│   │   └── state/
│   ├── radio-pop/
│   ├── radio-rock/
│   ├── radio-classicas/
│   ├── radio-country/
│   ├── tvkids-main/
│   ├── tvteens-main/
│   ├── tvviva-main/
│   └── tvmaisjovem-main/
└── objects/                # (opcional futuro – CAS)
```

Na reconstrução inicial **não** usaremos CAS complexo. Usaremos pastas `ready/` simples e determinísticas.

## 4. Nomes Canônicos das 9 Emissoras

| ID Canônico       | Tipo  | Observação                    |
|-------------------|-------|-------------------------------|
| radio-main        | Rádio | Fallback / estúdio ao vivo    |
| radio-pop         | Rádio | Catálogo pop                  |
| radio-rock        | Rádio | Catálogo rock                 |
| radio-classicas   | Rádio | Clássicas                     |
| radio-country     | Rádio | Country                       |
| tvkids-main       | TV    | Infantil                      |
| tvteens-main      | TV    | Adolescente                   |
| tvviva-main       | TV    | Viva                          |
| tvmaisjovem-main  | TV    | Mais Jovem                    |

## 5. Regras de Segurança Operacional

- Publish no MediaMTX apenas de `127.0.0.1` e `::1`.
- Nenhum publisher externo autorizado nesta fase.
- Todas as units rodam como usuário `tpsmedia`.
- Nenhuma mudança de configuração sem backup prévio.

## 6. Critério de Sucesso por Fase

Cada fase só é considerada concluída quando:

1. Os testes automatizados da fase passam.
2. O estado é registrado no repositório.
3. A próxima fase pode começar sem dependência de estado legado.
