# Arquitetura Alvo – NS1

```
Internet
   │
   ▼
[ DNS – BIND9 ]  ns1.tpsolutions.com.br / studiosatweb.com.br
   │
   ▼
[ Nginx ]  :80 / :443
   │  ├── Sites estáticos
   │  └── /hls/*  →  proxy_pass http://127.0.0.1:8888/
   │
   ▼
[ MediaMTX ]  :1935 (RTMP)  |  :8888 (HLS interno)  |  :9997 (API)
   │
   ├── radio-main      ← FFmpeg (tps-radio-main-playout)
   ├── radio-pop       ← FFmpeg (tps-radio-pop-playout)
   ├── radio-rock      ← FFmpeg (tps-radio-rock-playout)
   ├── radio-classicas ← FFmpeg (tps-radio-classicas-playout)
   ├── radio-country   ← FFmpeg (tps-radio-country-playout)
   ├── tvkids-main     ← FFmpeg (tps-tvkids-main-playout)
   ├── tvteens-main    ← FFmpeg (tps-tvteens-main-playout)
   ├── tvviva-main     ← FFmpeg (tps-tvviva-main-playout)
   └── tvmaisjovem-main← FFmpeg (tps-tvmaisjovem-main-playout)

[ Repositório ]
/srv/tpsmedia/repository/channels/<canal>/ready/
/srv/tpsmedia/repository/channels/<canal>/playlists/playlist.txt
```

## Princípios de Design

1. **Um publisher = um processo = uma unit systemd**
2. **Conexão RTMP nunca cai na troca de faixa**
3. **Conteúdo só entra por caminho controlado**
4. **Nenhuma dependência de scripts legados**
5. **Tudo documentado e versionado neste repositório**
