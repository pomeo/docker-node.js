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
    openssh-server \
    sudo

# OpenSSH
RUN mkdir /var/run/sshd
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Setup Node.js
RUN curl -sL https://deb.nodesource.com/setup_15.x | bash -
RUN apt install -y nodejs
RUN npm install pm2 -g

# Add user
RUN useradd -ms /bin/bash $USER
RUN adduser $USER sudo

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

CMD ["/usr/sbin/sshd", "-D"]
