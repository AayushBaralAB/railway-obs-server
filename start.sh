#!/bin/bash

set -e

echo "====================================="
echo " Railway Virtual OBS Server"
echo "====================================="

export DISPLAY=:1
export LIBGL_ALWAYS_SOFTWARE=1
export QT_X11_NO_MITSHM=1

# Virtual display
Xvfb :1 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &

sleep 3

# DBus
eval "$(dbus-launch --sh-syntax)"

# XFCE desktop
startxfce4 &

sleep 8

# VNC
x11vnc \
    -display :1 \
    -forever \
    -shared \
    -nopw \
    -rfbport 5900 \
    -noxdamage &

sleep 3

# noVNC
websockify \
    --web=/usr/share/novnc/ \
    ${PORT:-8080} \
    localhost:5900 &

echo "====================================="
echo "Virtual desktop is ready"
echo "DISPLAY=$DISPLAY"
echo "PORT=${PORT:-8080}"
echo "====================================="

# Keep container alive
exec tail -f /dev/null
