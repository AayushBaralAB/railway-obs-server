#!/bin/bash

set -e

echo "====================================="
echo " Railway Virtual OBS Server"
echo "====================================="

export LIBGL_ALWAYS_SOFTWARE=1
export QT_X11_NO_MITSHM=1
export DISPLAY=:1

# Start virtual display
Xvfb :1 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &

sleep 3

# Start DBus
eval "$(dbus-launch --sh-syntax)"

# Disable XFCE compositor
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

# Start XFCE
startxfce4 &

sleep 8

# Start VNC server
x11vnc \
    -display :1 \
    -forever \
    -shared \
    -nopw \
    -rfbport 5900 \
    -noxdamage &

sleep 3

# Start noVNC internally on port 6080
websockify \
    --web=/usr/share/novnc/ \
    6080 \
    localhost:5900 &

sleep 3

# Start Nginx on Railway public port
sed -i "s/listen 8080;/listen ${PORT:-8080};/" /etc/nginx/nginx.conf

nginx -t

nginx -g "daemon off;"
