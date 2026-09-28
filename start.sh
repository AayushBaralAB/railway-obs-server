#!/bin/bash

set -e

echo "====================================="
echo " Railway Virtual OBS Server"
echo "====================================="

export LIBGL_ALWAYS_SOFTWARE=1
export QT_X11_NO_MITSHM=1
export DISPLAY=:1

echo "[1/7] Starting Xvfb..."

Xvfb :1 \
    -screen 0 1280x720x24 \
    -ac \
    +extension GLX \
    +render \
    -noreset &

sleep 3

echo "[2/7] Starting DBus..."

eval "$(dbus-launch --sh-syntax)"

echo "[3/7] Starting XFCE..."

startxfce4 &

sleep 8

echo "[4/7] Starting x11vnc..."

x11vnc \
    -display :1 \
    -forever \
    -shared \
    -nopw \
    -rfbport 5900 \
    -noxdamage \
    -listen 127.0.0.1 &

sleep 3

echo "[5/7] Starting noVNC..."

websockify \
    --web=/usr/share/novnc \
    127.0.0.1:6080 \
    127.0.0.1:5900 &

sleep 3

echo "[6/7] Starting Login Server..."

python3 /login.py &

sleep 2

echo "[7/7] Starting Nginx..."

sed -i "s/listen 8080;/listen ${PORT:-8080};/" /etc/nginx/nginx.conf

nginx -t

echo "====================================="
echo " Login server ready"
echo " noVNC ready"
echo " Nginx ready"
echo "====================================="

nginx -g "daemon off;"
