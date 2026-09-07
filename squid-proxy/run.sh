#!/usr/bin/with-contenv bashio
# ==============================================================================
# SQUID PROXY ENTRYPOINT COM LOGS DETALHADOS
# ==============================================================================

# Desativa buffer de saída para garantir exibição imediata no Supervisor
export PYTHONUNBUFFERED=1

# Leitura segura do nível de log configurado
LOG_LEVEL=$(bashio::config 'log_level' 2>/dev/null || echo "debug")
if [ -z "${LOG_LEVEL}" ] || [ "${LOG_LEVEL}" = "null" ]; then
    LOG_LEVEL="debug"
fi

# Banner inicial emitido imediatamente para o log do Home Assistant
echo "============================================================"
echo "🦑 SQUID PROXY ADD-ON INICIALIZANDO"
echo "Versão do Add-on: 1.1.0"
echo "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Nível de Detalhe do Log: ${LOG_LEVEL}"
echo "============================================================"

# Se log_level for debug ou trace, ativa rastreamento linha a linha do bash
if [ "${LOG_LEVEL}" = "debug" ] || [ "${LOG_LEVEL}" = "trace" ]; then
    echo "🔍 [DEBUG] Modo de alta verbosidade ativo. Rastreando ambiente..."

    echo "--- [DIAGNÓSTICO DO SISTEMA] ---"
    uname -a
    
    echo "--- [DIAGNÓSTICO DO SQUID] ---"
    squid -v 2>&1 | head -n 4

    echo "--- [CONFIGURAÇÕES DO USUÁRIO (/data/options.json)] ---"
    cat /data/options.json 2>/dev/null || true
    echo ""
fi

# Leitura das opções via Bashio com fallbacks seguros
HTTP_PORT=$(bashio::config 'http_port' 2>/dev/null || echo "3128")
if [ -z "${HTTP_PORT}" ] || [ "${HTTP_PORT}" = "null" ]; then
    HTTP_PORT="3128"
fi

CACHE_SIZE_MB=$(bashio::config 'cache_size_mb' 2>/dev/null || echo "512")
if [ -z "${CACHE_SIZE_MB}" ] || [ "${CACHE_SIZE_MB}" = "null" ]; then
    CACHE_SIZE_MB="512"
fi

ENABLE_AUTH=$(bashio::config 'enable_auth' 2>/dev/null || echo "false")

echo "ℹ️ Configurações ativas:"
echo " - Porta HTTP: ${HTTP_PORT}"
echo " - Tamanho de Cache: ${CACHE_SIZE_MB} MB"
echo " - Autenticação Ativa: ${ENABLE_AUTH}"

# Assegura a estrutura de pastas e permissões
echo "🔧 Ajustando diretórios e permissões do sistema..."
mkdir -p /var/log/squid /var/spool/squid /etc/squid /run/squid /var/run/squid
chown -R squid:squid /var/log/squid /var/spool/squid /etc/squid /run/squid /var/run/squid
chmod 755 /run/squid /var/run/squid /var/log/squid /var/spool/squid
chmod 666 /dev/stdout /dev/stderr 2>/dev/null || true

# Configura o nível de debug do Squid conforme o log_level escolhido
SQUID_DEBUG_OPTIONS="ALL,1"
SQUID_DAEMON_FLAGS="-d 1"

if [ "${LOG_LEVEL}" = "debug" ]; then
    SQUID_DEBUG_OPTIONS="ALL,2"
    SQUID_DAEMON_FLAGS="-d 2 -X"
elif [ "${LOG_LEVEL}" = "trace" ]; then
    SQUID_DEBUG_OPTIONS="ALL,5"
    SQUID_DAEMON_FLAGS="-d 3 -X"
elif [ "${LOG_LEVEL}" = "warning" ] || [ "${LOG_LEVEL}" = "error" ]; then
    SQUID_DEBUG_OPTIONS="ALL,0"
    SQUID_DAEMON_FLAGS="-d 0"
fi

echo "📝 Gerando /etc/squid/squid.conf..."

cat << EOF > /etc/squid/squid.conf
# ==============================================================================
# SQUID PROXY CONFIGURATION (GERADO AUTOMATICAMENTE PELO SUPERVISOR)
# ==============================================================================

# Porta de escuta
http_port ${HTTP_PORT}

# Arquivo de PID seguro
pid_filename /run/squid/squid.pid

# Portas autorizadas (Safe Ports e SSL Ports)
acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # portas não registradas
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# Proteção padrão contra portas não seguras
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager

EOF

# Configuração de redes locais permitidas
echo "🌐 Configurando ACLs de redes locais permitidas..."
NETWORKS=$(bashio::config 'allowed_networks' 2>/dev/null || echo "192.168.0.0/16 10.0.0.0/8 172.16.0.0/12")
for net in ${NETWORKS}; do
    echo " - Permitindo acesso da rede: ${net}"
    echo "acl localnet src ${net}" >> /etc/squid/squid.conf
done

# Configuração de Autenticação Básica (se ativada)
if [ "${ENABLE_AUTH}" = "true" ]; then
    echo "🔒 Configurando autenticação de usuários..."
    USERNAME=$(bashio::config 'username' 2>/dev/null || true)
    PASSWORD=$(bashio::config 'password' 2>/dev/null || true)

    if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ] || [ "${USERNAME}" = "null" ]; then
        echo "❌ ERRO: enable_auth está ativado, mas username ou password está em branco!" >&2
        exit 1
    fi

    AUTH_HELPER=""
    for helper_candidate in /usr/lib/squid/basic_ncsa_auth /usr/lib/squid3/basic_ncsa_auth /usr/libexec/squid/basic_ncsa_auth; do
        if [ -x "${helper_candidate}" ]; then
            AUTH_HELPER="${helper_candidate}"
            break
        fi
    done

    if [ -z "${AUTH_HELPER}" ]; then
        AUTH_HELPER=$(which basic_ncsa_auth 2>/dev/null || true)
    fi

    if [ -z "${AUTH_HELPER}" ] || [ ! -x "${AUTH_HELPER}" ]; then
        echo "❌ ERRO: Helper basic_ncsa_auth não encontrado!" >&2
        exit 1
    fi

    echo " - Helper de autenticação encontrado: ${AUTH_HELPER}"
    htpasswd -b -c /etc/squid/passwords "${USERNAME}" "${PASSWORD}"
    chown squid:squid /etc/squid/passwords
    chmod 640 /etc/squid/passwords
    echo " - Arquivo de credenciais gerado para usuário: ${USERNAME}"

    cat << EOF >> /etc/squid/squid.conf
# Autenticação Básica
auth_param basic program ${AUTH_HELPER} /etc/squid/passwords
auth_param basic children 5
auth_param basic realm Servidor Squid Proxy Home Assistant
auth_param basic credentialsttl 2 hours
acl authenticated_users proxy_auth REQUIRED

http_access allow authenticated_users
http_access deny all
EOF
else
    echo "🔓 Autenticação desativada: redes locais têm acesso direto."
    cat << 'EOF' >> /etc/squid/squid.conf
http_access allow localnet
http_access allow localhost
http_access deny all
EOF
fi

# Diretivas de Privacidade e Logs
cat << EOF >> /etc/squid/squid.conf

# Anonimato e Limpeza de Headers
forwarded_for delete
via off

# Sistema de Logs Direcionado para o Console
logfile_rotate 0
access_log stdio:/dev/stdout combined
cache_log /dev/stderr
debug_options ${SQUID_DEBUG_OPTIONS}
EOF

# Configuração de Cache em Disco e RAM
cat << EOF >> /etc/squid/squid.conf

# Cache de Navegação
cache_dir ufs /var/spool/squid ${CACHE_SIZE_MB} 16 256
maximum_object_size 100 MB
cache_mem 64 MB
EOF

# Configurações personalizadas extras (se fornecidas)
CUSTOM_CFG=$(bashio::config 'custom_config' 2>/dev/null || true)
if [ -n "${CUSTOM_CFG}" ] && [ "${CUSTOM_CFG}" != "null" ]; then
    echo "⚙️ Adicionando linhas personalizadas extras ao squid.conf..."
    echo "" >> /etc/squid/squid.conf
    echo "# Custom Config (options.json)" >> /etc/squid/squid.conf
    echo "${CUSTOM_CFG}" >> /etc/squid/squid.conf
fi

# Exibe o arquivo de configuração se em modo de depuração
if [ "${LOG_LEVEL}" = "debug" ] || [ "${LOG_LEVEL}" = "trace" ]; then
    echo "--- [/etc/squid/squid.conf GERADO] ---"
    cat -n /etc/squid/squid.conf
    echo "--------------------------------------"
fi

# Validação prévia da sintaxe do Squid
echo "🧪 Validando sintaxe do Squid (squid -k parse)..."
if ! squid -k parse -f /etc/squid/squid.conf; then
    echo "❌ [ERRO DE SINTAXE] O Squid rejeitou o arquivo /etc/squid/squid.conf!" >&2
    exit 1
fi
echo "✅ Sintaxe do Squid validada com sucesso!"

# Inicializa o cache swap em disco se ainda não existir
if [ ! -d /var/spool/squid/00 ]; then
    echo "📁 Inicializando diretórios de cache em /var/spool/squid (squid -z)..."
    squid -z -N -f /etc/squid/squid.conf
    chown -R squid:squid /var/spool/squid
    echo "✅ Estrutura de cache swap criada com sucesso!"
fi

echo "============================================================"
echo "🚀 INICIANDO SQUID PROXY NA PORTA ${HTTP_PORT} (Foreground)..."
echo "Flags: ${SQUID_DAEMON_FLAGS}"
echo "============================================================"

# Executa o Squid redirecionando stdout e stderr para a saída do container
exec squid -N ${SQUID_DAEMON_FLAGS} -f /etc/squid/squid.conf
