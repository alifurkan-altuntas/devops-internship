#!/bin/bash

today=$(date +%Y-%m-%d)

mkdir -p ~/nginx_archive

gzip -c /var/log/nginx/access.log > ~/nginx_archive/access-$today.log.gz

sudo truncate -s 0 /var/log/nginx/access.log

echo "Log archived as access-$today.log.gz"