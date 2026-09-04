# Fase 2 – Repositório Canônico

**Objetivo:** Criar a estrutura limpa e determinística de conteúdo para as 9 emissoras.

## 2.1 Criar estrutura canônica

```bash
CHANNELS="radio-main radio-pop radio-rock radio-classicas radio-country tvkids-main tvteens-main tvviva-main tvmaisjovem-main"

for ch in $CHANNELS; do
  mkdir -p /srv/tpsmedia/repository/channels/$ch/{ready,playlists,state,incoming,quarantine,logs}
  chown -R tpsmedia:tpsmedia /srv/tpsmedia/repository/channels/$ch
  chmod -R 755 /srv/tpsmedia/repository/channels/$ch
done

# Verificar
find /srv/tpsmedia/repository/channels -maxdepth 2 -type d | sort
```

## 2.2 Política de conteúdo (fase inicial)

- Conteúdo entra **apenas** em `incoming/`
- Após validação manual ou script de ingestão, é movido para `ready/`
- A playlist oficial é gerada a partir de `ready/`

## 2.3 Script de geração de playlist (modelo)

```bash
# Exemplo para radio-pop (será parametrizado depois)
python3 - << 'EOF'
import os
channel = "radio-pop"
ready = f"/srv/tpsmedia/repository/channels/{channel}/ready"
playlist = f"/srv/tpsmedia/repository/channels/{channel}/playlists/playlist.txt"

files = sorted([f for f in os.listdir(ready) if f.lower().endswith((".mp3", ".mp4", ".m4a"))])
with open(playlist, "w") as out:
    out.write("ffconcat version 1.0\n")
    for f in files:
        out.write(f"file '{os.path.join(ready, f)}'\n")
    if files:
        out.write(f"file '{playlist}'\n")  # loop
print(f"Playlist gerada com {len(files)} itens")
EOF
```

## Critério de Saída da Fase 2

- [ ] 9 canais criados com subpastas padrão
- [ ] Ownership `tpsmedia:tpsmedia`
- [ ] Estrutura validada
- [ ] Pronto para receber conteúdo e avançar para Fase 3
