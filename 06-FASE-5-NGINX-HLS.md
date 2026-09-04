# Fase 5 – Nginx + HLS + Sites

**Objetivo:** Expor o HLS das emissoras de forma limpa e servir os sites.

## 5.1 Proxy HLS canônico

```nginx
location /hls/ {
    proxy_pass http://127.0.0.1:8888/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_buffering off;
    proxy_read_timeout 60s;
}
```

## 5.2 Healthcheck

```nginx
location = /healthz {
    return 200 "TPS-MEDIA-EDGE=OK\n";
}
```

## 5.3 Validação

```bash
curl -I http://127.0.0.1/healthz
curl -I http://127.0.0.1/hls/radio-pop/index.m3u8
```

## Critério de Saída da Fase 5

- [ ] HLS acessível localmente via Nginx
- [ ] Healthcheck respondendo
- [ ] Sites básicos servindo
