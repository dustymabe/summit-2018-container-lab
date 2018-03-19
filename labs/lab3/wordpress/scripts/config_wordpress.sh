#!/bin/bash

set -e

__handle_passwords() {
    if [ -z "$DB_ENV_DBNAME" ]; then
        cat <<EOF
No DB_ENV_DBNAME variable. Please link to database using alias 'db'
or provide DB_ENV_DBNAME variable.
EOF
        exit 1
    fi
    if [ -z "$DB_ENV_DBUSER" ]; then
        printf "No DB_ENV_DBUSER variable. Please link to database using alias 'db'.\n"
        exit 1
    fi
    # Here we generate random passwords (thank you pwgen!) for random keys in wp-config.php
    printf "Creating wp-config.php...\n"
    # There used to be a huge ugly line of sed and cat and pipe and stuff below,
    # but thanks to @djfiander's thing at https://gist.github.com/djfiander/6141138
    # there isn't now.
    sed -e "s/database_name_here/$DB_ENV_DBNAME/
    s/username_here/$DB_ENV_DBUSER/
    s/password_here/$DB_ENV_DBPASS/" /var/www/html/wp-config-sample.php > /var/www/html/wp-config.php
    #
    # Update keys/salts in wp-config for security
    RE='put your unique phrase here'
    for i in {1..8}; do
        KEY=$(openssl rand -base64 40)
        sed -i "0,/$RE/s|$RE|$KEY|" /var/www/html/wp-config.php
    done
}

__handle_db_host() {
    if [ "$MARIADB_SERVICE_HOST" ]; then
        # Update wp-config.php to point to our kubernetes service address.
        sed -i -e "s/^\(define('DB_HOST', '\).*\(');.*\)/\1$MARIADB_SERVICE_HOST:$MARIADB_SERVICE_PORT\2/" \
            /var/www/html/wp-config.php
    else
        # Update wp-config.php to point to our linked container's address.
        sed -i -e "s/^\(define('DB_HOST', '\).*\(');.*\)/\1${DB_PORT#tcp://}\2/" \
            /var/www/html/wp-config.php
    fi
}

__httpd_perms() {
    chown apache:apache /var/www/html/wp-config.php
}

__check() {
    if [ ! -f /var/www/html/wp-config.php ]; then
        __handle_passwords
        __httpd_perms
    fi
    __handle_db_host
}

# Call all functions
__check
