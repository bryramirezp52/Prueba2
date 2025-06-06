# Dockerfile optimizado para Nagios Core 4.5.9 con plugins 2.4.11 en Ubuntu 22.04

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    NAGIOS_VERSION=4.5.9 \
    PLUGINS_VERSION=2.4.11 \
    NAGIOS_USER=duoc \
    NAGIOS_GROUP=duoc \
    NAGIOS_PASS=duoc123 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2

# 1) Dependencias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential autoconf gcc pkg-config \
        libssl-dev libgd-dev libpng-dev libjpeg-dev \
        apache2 apache2-utils php libapache2-mod-php \
        libmariadb-dev libperl-dev libldap2-dev \
        snmp libsnmp-dev wget ca-certificates unzip curl bc && \
    rm -rf /var/lib/apt/lists/*

# 2) Usuario y grupo
RUN groupadd -r ${NAGIOS_GROUP} || true && \
    useradd -r -g ${NAGIOS_GROUP} -d /usr/local/nagios -s /bin/false -c "Nagios User" ${NAGIOS_USER} || true && \
    usermod -a -G ${NAGIOS_GROUP} ${APACHE_RUN_USER} || true

# 3) Compilar e instalar Nagios Core
RUN cd /tmp && \
    wget -q https://github.com/NagiosEnterprises/nagioscore/archive/refs/tags/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar xzf nagios-${NAGIOS_VERSION}.tar.gz && \
    cd nagioscore-nagios-${NAGIOS_VERSION} && \
    ./configure \
        --with-httpd-conf=/etc/apache2/sites-enabled \
        --with-nagios-user=${NAGIOS_USER} \
        --with-nagios-group=${NAGIOS_GROUP} \
        --with-command-user=${NAGIOS_USER} \
        --with-command-group=${NAGIOS_GROUP} && \
    make all && \
    make install-groups-users && \
    make install && \
    make install-daemoninit && \
    make install-commandmode && \
    make install-config && \
    make install-webconf && \
    a2enmod cgi alias authn_file auth_basic authz_core rewrite

# 4) Desactivar sitio por defecto y redirigir “/” → “/nagios/”
RUN a2dissite 000-default.conf && \
    echo 'RedirectMatch ^/$ /nagios/' > /etc/apache2/conf-available/redirect-root.conf && \
    a2enconf redirect-root

# 5) Plugins de Nagios
RUN cd /tmp && \
    wget -q https://nagios-plugins.org/download/nagios-plugins-${PLUGINS_VERSION}.tar.gz && \
    tar xzf nagios-plugins-${PLUGINS_VERSION}.tar.gz && \
    cd nagios-plugins-${PLUGINS_VERSION} && \
    ./configure --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_GROUP} --with-perl=/usr/bin/perl && \
    make && \
    make install

# 6) Credenciales + permisos
RUN mkdir -p /usr/local/nagios/etc && \
    htpasswd -bc /usr/local/nagios/etc/htpasswd.users ${NAGIOS_USER} ${NAGIOS_PASS} && \
    chown ${NAGIOS_USER}:${NAGIOS_GROUP} /usr/local/nagios/etc/htpasswd.users && \
    chmod 640 /usr/local/nagios/etc/htpasswd.users && \
    chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} /usr/local/nagios/var/rw && \
    chmod -R g+rwx /usr/local/nagios/var/rw

# 7) Limpiar tmp
RUN rm -rf /tmp/*

# 8) Exponer puerto 80
EXPOSE 80

# 9) ServerName para Apache
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && \
    a2enconf servername

# 10) Healthcheck básico
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s \
  CMD curl -fs --user ${NAGIOS_USER}:${NAGIOS_PASS} http://localhost/nagios/ || exit 1

# 11) Lanzar Nagios + Apache (manteniendo advertencia leve de JSONArgs)
CMD ["/bin/bash", "-c", "/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg && /usr/local/nagios/bin/nagios -d /usr/local/nagios/etc/nagios.cfg && exec apache2ctl -D FOREGROUND"]
