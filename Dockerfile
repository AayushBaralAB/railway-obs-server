FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    supervisor \
    wget \
    curl \
    dbus-x11 \
    pulseaudio \
    pulseaudio-utils \
    alsa-utils \
    ffmpeg \
    nginx \
    python3 \
    apache2-utils \
    libgl1-mesa-dri \
    libegl1 \
    libglx-mesa0 \
    mesa-utils \
    libx11-xcb1 \
    libxcb-xinerama0 \
    libxcb-cursor0 \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:obsproject/obs-studio \
    && apt-get update \
    && apt-get install -y obs-studio \
    && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /start.sh
COPY login.py /login.py

RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
