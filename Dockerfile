FROM monica:2.19.1-fpm

RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        wget \
        apt-transport-https \
        ca-certificates \
        gnupg-agent gnupg2 \
        software-properties-common \
    ; \
    rm -rf /var/lib/apt/lists/*

COPY setup.sh /opt/app/
RUN /opt/app/setup.sh

RUN mv /var/www /opt/www
RUN rm -rf /opt/www/html/storage && ln -s /var/www/html/storage /opt/www/html/storage
RUN rm /opt/www/html/.env && ln -s /var/www/html/.env /opt/www/html/.env
RUN ln -s /var/www/html/storage /opt/www/html/public/storage

RUN sed --in-place='' \
        --expression='s/^    MONICADIR=\/var\/www\/html/    MONICADIR=\/opt\/www\/html/' \
        --expression='s/^    waitfordb$/    # waitfordb/' \
        --expression='s/^    chown -R www-data:www-data/    # chown -R www-data:www-data/' \
        /usr/local/bin/entrypoint.sh

# COPY opt/app/launcher.sh /opt/app/
# COPY opt/app/service-config/nginx.conf /opt/app/service-config/nginx.conf
# COPY opt/app/service-config/mime.types /opt/app/service-config/mime.types
