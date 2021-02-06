FROM monica:2.19.1-fpm AS monica-base
RUN echo $MONICA_VERSION > /monica_version

FROM node:lts AS js-builder
COPY --from=monica-base /monica_version /monica_version

RUN set -ex; \
    export MONICA_VERSION="$(cat /monica_version)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends gnupg; \
    rm -rf /var/lib/apt/lists/* ; \
    \
    for ext in tar.bz2 tar.bz2.asc; do \
        curl -fsSL -o monica-$MONICA_VERSION.$ext "https://github.com/monicahq/monica/releases/download/$MONICA_VERSION/monica-$MONICA_VERSION.$ext"; \
    done; \
    \
    GPGKEY='BDAB0D0D36A00466A2964E85DE15667131EA6018'; \
    export GNUPGHOME="$(mktemp -d)"; \
    echo "disable-ipv6" >> $GNUPGHOME/dirmngr.conf ; \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPGKEY"; \
    gpg --batch --verify monica-$MONICA_VERSION.tar.bz2.asc monica-$MONICA_VERSION.tar.bz2; \
    \
    mkdir /app; \
    tar -xf monica-$MONICA_VERSION.tar.bz2 -C /app --strip-components=1; \
    \
    gpgconf --kill all; \
    rm -r "$GNUPGHOME" monica-$MONICA_VERSION.tar.bz2 monica-$MONICA_VERSION.tar.bz2.asc

WORKDIR /app
RUN yarn install --ignore-engines --frozen-lockfile --ignore-scripts

COPY monica-js-fixes.patch .
RUN git apply --unsafe-paths monica-js-fixes.patch

RUN yarn run production

FROM monica-base

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

COPY monica-fixes.patch monica-xsrf-fixes.patch /opt/app/
RUN cd /opt/www/html \
 && git apply --unsafe-paths /opt/app/monica-fixes.patch \
 && git apply --unsafe-paths /opt/app/monica-xsrf-fixes.patch

COPY --from=js-builder /app/public/js/vendor.js /opt/www/html/public/js/vendor.js

# COPY opt/app/launcher.sh /opt/app/
# COPY opt/app/service-config/nginx.conf /opt/app/service-config/nginx.conf
# COPY opt/app/service-config/mime.types /opt/app/service-config/mime.types
