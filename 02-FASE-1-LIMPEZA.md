# Fase 1 – Limpeza Controlada

**Objetivo:** Remover resíduos de tentativas anteriores sem destruir o que ainda é útil (MediaMTX, Nginx, BIND).

## 1.1 Units de Playout Legadas

```bash
# Listar
ls -la /etc/systemd/system/tps-*-playout* 2>/dev/null || true

# Remover
rm -f /etc/systemd/system/tps-*-playout*.service
systemctl daemon-reload
```

## 1.2 Processos FFmpeg residuais

```bash
pkill -u tpsmedia ffmpeg 2>/dev/null || true
ps aux | grep ffmpeg | grep -v grep || echo "Limpo"
```

## 1.3 Paths legados no MediaMTX (não reiniciar ainda)

Apenas registrar. A reconstrução do MediaMTX será feita na Fase 3.

```bash
curl -s http://127.0.0.1:9997/v3/paths/list | python3 -m json.tool || true
```

## 1.4 Diretórios de conteúdo inconsistentes

```bash
# Apenas inventário – não apagar ainda
find /srv/tpsmedia -maxdepth 3 -type d 2>/dev/null | sort
du -sh /srv/tpsmedia/* 2>/dev/null || true
```

## Critério de Saída da Fase 1

- [ ] Nenhuma unit `tps-*-playout` residual
- [ ] Nenhum processo FFmpeg de playout ativo
- [ ] Inventário de diretórios registrado
- [ ] Pronto para Fase 2
