# Home Assistant Add-on: Squid Proxy (v1.1.0)

O **Squid Proxy** é um servidor de proxy HTTP/HTTPS de alto desempenho para a sua rede local, com suporte a cache, controle de sub-redes autorizadas, autenticação básica opcional e **sistema de diagnóstico de logs em tempo real**.

---

## ⚙️ Opções de Configuração

| Parâmetro | Padrão | Opções | Descrição |
| :--- | :--- | :--- | :--- |
| `log_level` | `debug` | `trace`, `debug`, `info`, `notice`, `warning`, `error` | Controla o nível de detalhamento dos logs no console do add-on e no Squid. |
| `http_port` | `3128` | número de porta | Porta interna onde o Squid escuta. |
| `allowed_networks` | `["192.168.0.0/16", ...]` | lista de sub-redes CIDR | Redes autorizadas a utilizar o proxy. |
| `cache_size_mb` | `512` | tamanho em MB | Tamanho do cache de objetos em disco. |
| `enable_auth` | `false` | `true` ou `false` | Ativa a autenticação por usuário e senha. |
| `username` | `""` | texto | Nome de usuário (necessário se `enable_auth: true`). |
| `password` | `""` | texto/senha | Senha (necessário se `enable_auth: true`). |
| `custom_config` | `""` | texto livre | Diretivas adicionais personalizadas para o `squid.conf`. |

---

## 🔍 Níveis de Log e Diagnóstico

- **`debug` (Recomendado para testes)**:
  - Ativa o modo de rastreamento linha a linha do script de inicialização (`set -x`).
  - Imprime o diagnóstico completo do sistema operacional e da versão do Squid.
  - Imprime o arquivo `/etc/squid/squid.conf` gerado na íntegra no log.
  - Executa `squid -k parse` para validar a sintaxe antes de subir o serviço.
  - Ativa o modo `-d 2 -X` do daemon do Squid para exibir conexões e handshakes.
- **`trace`**: Nível máximo de verbosidade (`debug_options ALL,5` e `-d 3`).
- **`info`**: Exibe o banner, a confirmação dos serviços e o log de acesso padrão das requisições HTTP/HTTPS.

---

## 🚨 O que fazer se o Add-on não iniciar ou o log estiver vazio?

Se ao clicar em "Iniciar" o add-on parar imediatamente sem nada na aba **Log**:
1. O Docker pode ter falhado no build ou no bind de porta.
2. Acesse no Home Assistant: **Configurações > Sistema > Logs** (Settings > System > Logs).
3. No seletor do canto superior direito, escolha **Supervisor**.
4. Procure pelas linhas em vermelho com `addon_local_squid_proxy`. Lá o Supervisor informa o motivo exato de qualquer bloqueio do container (por exemplo, porta 3128 já ocupada por outro serviço na máquina).
