#!/bin/bash -x

# This step starts a web server to host the ostree repo.

set -e -o pipefail

# Start a web server for that directory
NGINX_CONFIG="$(pwd)/nginx.conf"
cat > "${NGINX_CONFIG}" <<EOF
worker_processes 8;
events {
}
http {
    access_log /dev/null;
    error_log  $(pwd)/nginx_error.log;
    server {
        listen 0.0.0.0:8080;
        root   $(pwd);
    }
}
pid $(pwd)/nginx.pid;
daemon on;
EOF
nginx -c "${NGINX_CONFIG}" -e "$(pwd)/nginx.log"
