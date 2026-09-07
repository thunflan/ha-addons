# Home Assistant Add-ons Repository 🦑

Repositório de add-ons personalizados para o **Home Assistant**, mantido por [Junior Bocchini](https://github.com/thunflan).

---

## 📦 Add-ons Disponíveis

### 1. [Squid Proxy](squid-proxy/)
Servidor de proxy HTTP/HTTPS de alto desempenho com suporte a cache de navegação, controle de sub-redes permitidas, autenticação básica opcional (`htpasswd`) e sistema completo de diagnósticos de logs.

- **Porta padrão**: `3128/tcp` (ou personalizável via NAT, ex: `8128`)
- **Arquiteturas suportadas**: `amd64`, `aarch64`, `armhf`, `armv7`, `i386`
- **Recursos**:
  - Túnel seguro HTTPS (CONNECT method)
  - Autenticação de usuários para acesso remoto seguro
  - Cache de navegação em disco e RAM
  - Diagnóstico em tempo real com `log_level: debug/trace`

---

## 🚀 Como Adicionar este Repositório ao Home Assistant

### Método 1: Adicionar com 1 Clique (My Home Assistant)

Clique no botão abaixo para adicionar este repositório diretamente na loja de add-ons do seu Home Assistant:

[![Adicionar Repositório ao Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fthunflan%2Fha-addons)

---

### Método 2: Instalação Manual

1. No Home Assistant, acesse **Configurações** > **Add-ons** > **Loja de Add-ons** (canto inferior direito).
2. Clique no ícone de **três pontinhos** no canto superior direito e selecione **Repositórios**.
3. No campo de texto, cole a URL deste repositório:
   ```
   https://github.com/thunflan/ha-addons
   ```
4. Clique em **Adicionar** e depois em **Fechar**.
5. Recarregue a página da Loja de Add-ons: a categoria **Junior's Home Assistant Add-ons** aparecerá contendo o **Squid Proxy**.
6. Clique no add-on, selecione **Instalar**, ajuste as configurações na aba **Configuração** e clique em **Iniciar**.

---

## ⚙️ Exemplo de Configuração (Squid Proxy)

Exemplo com autenticação para acesso remoto seguro (PC pessoal / fora de casa):

```yaml
log_level: info
http_port: 3128
allowed_networks:
  - 0.0.0.0/0
cache_size_mb: 512
enable_auth: true
username: "seu_usuario"
password: "sua_senha"
```

---

## 📄 Licença

Este repositório está sob a licença [MIT](LICENSE).
