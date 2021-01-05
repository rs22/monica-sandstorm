#!/bin/bash

# Create a bunch of folders under the clean /var that php, nginx, and mysql expect to exist
mkdir -p /var/lib/mysql
mkdir -p /var/lib/mysql-files
mkdir -p /var/lib/nginx
mkdir -p /var/lib/php/sessions
mkdir -p /var/log
mkdir -p /var/log/mysql
mkdir -p /var/log/nginx
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run/php
rm -rf /var/tmp
mkdir -p /var/tmp
mkdir -p /var/run/mysqld

# Ensure mysql tables created
# HOME=/etc/mysql /usr/bin/mysql_install_db
HOME=/etc/mysql /usr/sbin/mysqld --initialize

# Spawn mysqld
HOME=/etc/mysql /usr/sbin/mysqld --skip-grant-tables &

# Wait until mysql has bound its socket, indicating readiness
while [ ! -e /var/run/mysqld/mysqld.sock ] ; do
    echo "waiting for mysql to be available at /var/run/mysqld/mysqld.sock"
    sleep .2
done

# Spawn php
# /usr/local/bin/entrypoint.sh php-fpm --nodaemonize --fpm-config /usr/local/etc/php-fpm.conf &
# while [ ! -e /var/run/php/php-fpm.sock ] ; do
#     echo "waiting for php-fpm to be available at /var/run/php/php-fpm.sock"
#     sleep .2
# done

# Start nginx.
/usr/sbin/nginx -c /opt/app/service-config/nginx.conf -g "daemon off;"
