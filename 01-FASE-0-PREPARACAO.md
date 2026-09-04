# Fase 0 – Preparação e Congelamento

**Objetivo:** Preparar o ambiente para reconstrução sem risco de interferência de processos legados.

## 0.1 Checklist de Acesso

- [ ] Acesso root via MobaXterm ou Cloud Shell funcionando
- [ ] IP externo `35.231.174.46` alcançável
- [ ] Usuário `tpsmedia` existe

## 0.2 Congelamento de Produção

```bash
# Parar qualquer publisher legado (se existir)
systemctl stop tps-*-playout.service 2>/dev/null || true
systemctl disable tps-*-playout.service 2>/dev/null || true

# Verificar que não há FFmpeg publicando
ps aux | grep ffmpeg | grep -v grep || echo "Nenhum ffmpeg ativo"
```

## 0.3 Backup de Segurança (obrigatório)

```bash
BACKUP_DIR="/root/TPS-REBUILD-BACKUP-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BACKUP_DIR"

# Configurações críticas
cp -a /etc/tpsmedia "$BACKUP_DIR/" 2>/dev/null || true
cp -a /etc/nginx "$BACKUP_DIR/" 2>/dev/null || true
cp -a /etc/bind "$BACKUP_DIR/" 2>/dev/null || true
cp -a /etc/systemd/system/tps-* "$BACKUP_DIR/" 2>/dev/null || true

# Estado atual do MediaMTX
curl -s http://127.0.0.1:9997/v3/paths/list > "$BACKUP_DIR/mediamtx-paths-before.json" 2>/dev/null || true

echo "Backup criado em: $BACKUP_DIR"
```

## 0.4 Validação de Usuário e Diretórios Base

```bash
id tpsmedia || useradd -r -s /usr/sbin/nologin -d /srv/tpsmedia tpsmedia

mkdir -p /srv/tpsmedia/{repository,www,logs}
chown -R tpsmedia:tpsmedia /srv/tpsmedia
```

## Critério de Saída da Fase 0

- [ ] Backup completo realizado
- [ ] Nenhum publisher legado ativo
- [ ] Usuário `tpsmedia` e diretórios base existem
- [ ] Pronto para Fase 1
