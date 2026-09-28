#!/bin/bash

set -e

echo "====================================="
echo " Railway Virtual OBS Server"
echo "====================================="

# Start virtual display
Xvfb :1 -screen 0 1280x720x24 &

export DISPLAY=:1

sleep 2

# Start XFCE desktop
dbus-launch --exit-with-session startxfce4 &

sleep 5

# Start VNC
x11vnc \
    -display :1 \
    -forever \
    -shared \
    -nopw \
    -rfbport 5900 &

sleep 2

# Start noVNC
websockify \
    --web=/usr/share/novnc/ \
    8080 \
    localhost:5900 &

echo "Desktop started."
echo "noVNC listening on port 8080."

# Start supervisor
exec /usr/bin/supervisord -n
