# Fase 4 – Playout 24×7 (9 emissoras)

**Objetivo:** Colocar as 9 emissoras no ar com publisher persistente.

## 4.1 Modelo de Unit (Rádio – somente áudio)

```ini
[Unit]
Description=TPS radio-pop Continuous Playout 24x7
After=network.target tps-mediamtx.service
Requires=tps-mediamtx.service

[Service]
Type=simple
User=tpsmedia
Group=tpsmedia
Restart=always
RestartSec=3
ExecStart=/usr/bin/ffmpeg -hide_banner -loglevel warning -nostdin -re -f concat -safe 0 -i /srv/tpsmedia/repository/channels/radio-pop/playlists/playlist.txt -map 0:a:0 -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv rtmp://127.0.0.1:1935/radio-pop
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tps-radio-pop

[Install]
WantedBy=multi-user.target
```

## 4.2 Modelo de Unit (TV – vídeo + áudio)

```ini
ExecStart=/usr/bin/ffmpeg -hide_banner -loglevel warning -nostdin -re -f concat -safe 0 -i /srv/tpsmedia/repository/channels/tvkids-main/playlists/playlist.txt -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p -r 30 -g 60 -c:a aac -b:a 128k -ar 48000 -ac 2 -f flv rtmp://127.0.0.1:1935/tvkids-main
```

## 4.3 Ordem de ativação recomendada

1. radio-pop
2. radio-rock
3. radio-classicas
4. tvteens-main
5. tvviva-main
6. tvmaisjovem-main
7. tvkids-main
8. radio-country
9. radio-main (fallback)

## 4.4 Validação por emissora

```bash
systemctl is-active tps-radio-pop-playout
curl -s http://127.0.0.1:9997/v3/paths/list | python3 -c '
import sys, json
data = json.load(sys.stdin)
for p in data.get("items", []):
    if p["name"] == "radio-pop":
        print("ready:", p.get("ready"), "online:", p.get("online"), "bytes:", p.get("bytesReceived"))
'
```

## Critério de Saída da Fase 4

- [ ] Pelo menos as emissoras com conteúdo estão `ready=true` e `online=true`
- [ ] Bytes recebidos > 0
- [ ] Units habilitadas e com restart automático
