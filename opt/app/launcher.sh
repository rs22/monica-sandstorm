#!/bin/bash -e

cd /opt/www/html

# Monica environment
export DB_HOST=127.0.0.1
export DB_DATABASE=monica
export DB_USERNAME=root
export DB_PASSWORD=

export PHP_OPCACHE_MEMORY_CONSUMPTION=192

# export APP_ENV=local
# export APP_DEBUG=TRUE

# Prepare monica files and folders
mkdir -p /var/www/html/storage
if [ ! -f /var/www/html/.env ]; then cp /opt/www/html/.env.example /var/www/html/.env; fi

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
HOME=/etc/mysql /usr/sbin/mysqld --initialize \
    || true  # Ignore errors if mysql was previously initialized

# Spawn mysqld
HOME=/etc/mysql /usr/sbin/mysqld --skip-grant-tables &

# Wait until mysql has bound its socket, indicating readiness
while [ ! -e /var/run/mysqld/mysqld.sock ] ; do
    echo "waiting for mysql to be available at /var/run/mysqld/mysqld.sock"
    sleep .2
done

# Create a database
# echo "CREATE DATABASE IF NOT EXISTS $DB_DATABASE; GRANT ALL on $DB_DATABASE.* TO '$DB_USERNAME'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';" | mysql -uroot
echo "CREATE DATABASE IF NOT EXISTS $DB_DATABASE" | mysql -uroot

# Spawn php
/usr/local/bin/entrypoint.sh php-fpm --nodaemonize --fpm-config /usr/local/etc/php-fpm.conf &
while [ ! -e /var/run/php/php-fpm.sock ] ; do
    echo "waiting for php-fpm to be available at /var/run/php/php-fpm.sock"
    sleep .2
done

# Start nginx.
/usr/sbin/nginx -c /opt/app/service-config/nginx.conf -g "daemon off;"
