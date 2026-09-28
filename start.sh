#!/bin/bash

echo "====================================="
echo " Railway Virtual OBS Server"
echo " START SCRIPT VERSION: 2026-09-28"
echo "====================================="

set -u

echo "[1] Xvfb"
Xvfb :1 -screen 0 1280x720x24 &
sleep 3

export DISPLAY=:1

echo "[2] XFCE"
startxfce4 &
sleep 8

echo "[3] x11vnc"
x11vnc \
  -display :1 \
  -forever \
  -shared \
  -rfbport 5900 \
  -localhost \
  -nopw \
  -noxdamage &

sleep 3

echo "[4] websockify"
websockify \
  --web=/usr/share/novnc \
  6080 \
  localhost:5900 &

sleep 3

echo "[5] LOGIN SERVER"
python3 /login.py > /var/log/login.log 2>&1 &

sleep 2

echo "===== LOGIN LOG ====="
cat /var/log/login.log || true
echo "====================="

echo "[6] NGINX"

PORT_VALUE="${PORT:-8080}"

sed -i "s/listen 8080;/listen ${PORT_VALUE};/" /etc/nginx/nginx.conf

echo "PORT = ${PORT_VALUE}"

nginx -t

echo "===== NGINX START ====="
exec nginx -g "daemon off;"
