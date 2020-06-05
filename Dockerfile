FROM ubuntu:xenial

# Config ali repository
COPY assets/sources.list /etc/apt/sources.list

# Update APT repository and install packages
RUN apt-get -q update                  \
 && apt-get -y install ca-certificates wget xz-utils bzip2 gpgv gnupg nginx supervisor \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Config Aptly
COPY assets/aptly /usr/local/bin/aptly
COPY assets/aptly.conf /etc/aptly.conf

# Config Nginx
COPY assets/nginx.conf.sh /opt/nginx.conf.sh
COPY assets/supervisord.nginx.conf /etc/supervisor/conf.d/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Install scripts
COPY assets/*.sh /opt/
COPY assets/import_package/*.sh /opt/import_package/

# Bind mount location
VOLUME [ "/var/lib/aptly" ]

# Execute Startup script when container starts
ENTRYPOINT [ "/opt/startup.sh" ]
