# Fase 3 – MediaMTX Canônico

**Objetivo:** Garantir configuração limpa, previsível e segura do MediaMTX.

## 3.1 Backup da configuração atual

```bash
cp -a /etc/tpsmedia/mediamtx/mediamtx.yml /etc/tpsmedia/mediamtx/mediamtx.yml.bak-$(date +%Y%m%d%H%M%S)
```

## 3.2 Configuração alvo (resumo)

- RTMP na porta 1935
- HLS interno em 127.0.0.1:8888
- API em 127.0.0.1:9997
- Auth: publish apenas de localhost
- Paths explícitos para as 9 emissoras

## 3.3 Paths obrigatórios

```yaml
paths:
  radio-main:
    source: publisher
  radio-pop:
    source: publisher
  radio-rock:
    source: publisher
  radio-classicas:
    source: publisher
  radio-country:
    source: publisher
  tvkids-main:
    source: publisher
  tvteens-main:
    source: publisher
  tvviva-main:
    source: publisher
  tvmaisjovem-main:
    source: publisher
```

## 3.4 Validação

```bash
systemctl restart tps-mediamtx
sleep 2
systemctl is-active tps-mediamtx
curl -s http://127.0.0.1:9997/v3/paths/list | python3 -m json.tool
```

## Critério de Saída da Fase 3

- [ ] MediaMTX ativo
- [ ] 9 paths definidos
- [ ] API respondendo
- [ ] Pronto para Fase 4
