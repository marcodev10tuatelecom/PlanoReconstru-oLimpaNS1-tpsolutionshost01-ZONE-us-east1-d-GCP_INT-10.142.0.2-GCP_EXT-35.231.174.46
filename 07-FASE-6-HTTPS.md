# Fase 6 – HTTPS / TLS

**Objetivo:** Restaurar a porta 443 com certificados válidos.

## 6.1 Situação atual

- Certificados Let’s Encrypt existem e estão válidos (~52 dias restantes)
- Porta 443 **não está escutando**

## 6.2 Ações

1. Verificar se os certificados estão em `/etc/letsencrypt/live/`
2. Configurar server blocks HTTPS no Nginx apontando para esses certificados
3. Testar `nginx -t` e recarregar
4. Confirmar que a porta 443 passa a escutar

## Critério de Saída da Fase 6

- [ ] Porta 443 escutando
- [ ] HTTPS respondendo com certificado válido
- [ ] Redirecionamento HTTP → HTTPS (opcional mas recomendado)
