#!/bin/sh

# Update nginx to match worker_processes to no. of cpu's
procs=$(cat /proc/cpuinfo | grep processor | wc -l)
sed -i -e "s/worker_processes  1/worker_processes $procs/" /etc/nginx/nginx.conf

# set crontab
# crontab -l | { cat; echo "*/15 * * * * curl http://127.0.0.1:1324/cron/${CRON_KEY}"; } | crontab -

# Always chown webroot for better mounting
chown -Rf nginx:nginx /usr/share/nginx/html/api

# Start supervisord and services
supervisord -n -c /etc/supervisor/conf.d/supervisord.conf

