#!/bin/bash

set -e

if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]
then
    echo "Bench already exists, skipping init"
    exit 0
fi

rm -rf /workspaces/frappe_codespace/.git

source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18

echo "nvm use 18" >> ~/.bashrc
cd /workspace

bench init \
--ignore-exist \
--skip-redis-config-generation \
--frappe-branch version-15 \
frappe-bench

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Remove redis from Procfile
sed -i '/redis/d' ./Procfile

bench new-site dev.localhost \
--mariadb-root-password 123 \
--admin-password admin \
--no-mariadb-socket

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost
mv /workspace/frappe-bench/temp/* /workspace/frappe-bench/sites/dev.localhost/private/backups/

# Install Frappe Insights
bench get-app https://github.com/frappe/insights
bench --site dev.localhost install-app insights
bench --site dev.localhost --force restore --mariadb-root-password 123 /workspace/frappe-bench/sites/dev.localhost/private/backups/20241118_190300-dev_localhost-database.sql.gz --with-public-files /workspace/frappe-bench/sites/dev.localhost/private/backups/20241118_190300-dev_localhost-files.tar --with-private-files /workspace/frappe-bench/sites/dev.localhost/private/backups/20241118_190300-dev_localhost-private-files.tar
bench --site dev.localhost migrate


echo "Frappe Insights installation completed!"
