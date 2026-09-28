#!/bin/bash

set -u

echo "====================================="
echo " Railway Virtual OBS Server"
echo "====================================="

echo "[1/6] Starting Xvfb..."
Xvfb :1 -screen 0 1280x720x24 &
sleep 3

export DISPLAY=:1

echo "[2/6] Starting XFCE..."
startxfce4 &
sleep 8

echo "[3/6] Starting x11vnc..."
x11vnc \
  -display :1 \
  -forever \
  -shared \
  -rfbport 5900 \
  -localhost \
  -nopw \
  -noxdamage &

sleep 3

echo "[4/6] Starting websockify..."
websockify \
  --web=/usr/share/novnc \
  6080 \
  localhost:5900 &

sleep 3

echo "[5/6] Starting login server..."
python3 /login.py > /var/log/login.log 2>&1 &

sleep 3

echo "----- LOGIN SERVER LOG -----"
cat /var/log/login.log || true
echo "----------------------------"

echo "[6/6] Starting Nginx..."

PORT_VALUE="${PORT:-8080}"

sed -i "s/listen 8080;/listen ${PORT_VALUE};/" /etc/nginx/nginx.conf

echo "Nginx will listen on port: ${PORT_VALUE}"

nginx -t

echo "Starting Nginx..."
exec nginx -g "daemon off;"
