## -*- docker-image-name: "node.js" -*-
FROM ubuntu:latest
MAINTAINER Sergey Ovechkin <me@pomeo.me>
ENV USER ubuntu

# Update packages
RUN ln -snf /bin/bash /bin/sh
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow
RUN apt update
RUN apt upgrade -y
RUN apt install -y \
    git-core \
    curl \
    build-essential \
    libssl-dev \
    pkg-config \
    libexpat1-dev \
    libicu-dev \
    libcairo2-dev \
    libjpeg8-dev \
    libgif-dev \
    libpango1.0-dev \
    g++ \
    nano \
    gcc \
    make \
    ruby \
    openssh-server \
    openssh-client \
    supervisor \
    sudo

# Capistrano
RUN gem install capistrano -v 2.15.9

# OpenSSH
RUN mkdir /var/run/sshd
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Add user
RUN useradd -ms /bin/bash $USER
RUN adduser $USER sudo

# Setup Node.js
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt install -y nodejs
RUN npm install pm2 -g
RUN env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER

RUN echo "$USER:$USER" | chpasswd
USER $USER
WORKDIR /home/$USER

# Capistrano dirs
RUN mkdir -p ~/www/logs
RUN mkdir -p ~/www/shared
RUN mkdir -p ~/www/releases

USER root

EXPOSE 22
EXPOSE 3000

CMD ["/usr/bin/supervisord"]
