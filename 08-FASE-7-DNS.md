# Fase 7 – DNS e Validação Pública

**Objetivo:** Garantir que a resolução pública e a autoridade DNS estejam corretas.

## 7.1 Verificações

```bash
dig +short ns1.tpsolutions.com.br A
dig +short studiosatweb.com.br NS
dig +trace tpsolutions.com.br NS
```

## 7.2 Perspectiva externa

Após as fases anteriores, validar de fora do servidor:

- Resolução dos nomes públicos
- Acesso HTTPS
- Acesso HLS público

## Critério de Saída da Fase 7

- [ ] DNS autoridade respondendo corretamente
- [ ] Nomes públicos resolvendo
- [ ] Acesso externo funcional
