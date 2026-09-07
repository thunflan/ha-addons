FROM ghcr.io/home-assistant/base:latest

LABEL \
  io.hass.version="1.1.0" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64|armhf|armv7|i386"

# Instala o Squid, apache2-utils (htpasswd), curl, bash e dos2unix
RUN apk add --no-cache \
    squid \
    apache2-utils \
    curl \
    bash \
    dos2unix

# Prepara diretórios de cache, logs e run do Squid com permissões corretas
RUN mkdir -p /var/log/squid /var/spool/squid /etc/squid /run/squid /var/run/squid \
    && chown -R squid:squid /var/log/squid /var/spool/squid /run/squid /var/run/squid \
    && chmod 755 /run/squid /var/run/squid

# Copia script de execução, converte para LF e garante permissão de execução
COPY run.sh /run.sh
RUN dos2unix /run.sh \
    && sed -i -e 's/\r$//' /run.sh \
    && chmod a+x /run.sh

CMD [ "/run.sh" ]
