#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# ── System packages ───────────────────────────────────────────────────────────
# mysql-server não é necessário: o banco de dados é gerenciado pelo RDS
apt update -y

apt -y install \
    net-tools \
    python3-pip \
    python3-venv \
    pkg-config \
    default-libmysqlclient-dev \
    nginx

# ── Python virtual environment + dependências ─────────────────────────────────
mkdir -p /home/ubuntu/myapp
cd /home/ubuntu/myapp
python3 -m venv .
source ./bin/activate
pip install \
    flask \
    flask-mysqldb \
    flask-cors

chown -R ubuntu:ubuntu /home/ubuntu/myapp

# ── Systemd service para a API Flask ─────────────────────────────────────────
# O código (myapi.py) será entregue pelo GitHub Actions após o provisionamento.
cat > /etc/systemd/system/myapp.service <<SERVICE
[Unit]
Description=MyApp Flask API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/myapp
ExecStart=/home/ubuntu/myapp/bin/python /home/ubuntu/myapp/myapi.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable myapp

# ── Nginx – frontend estático ─────────────────────────────────────────────────
# O index.html será entregue pelo GitHub Actions após o provisionamento.
cat > /etc/nginx/sites-available/default <<NGINX
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX

nginx -t
systemctl restart nginx

chown ubuntu:ubuntu /var/www/html