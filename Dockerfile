## -*- docker-image-name: "node.js" -*-
FROM ubuntu:latest
MAINTAINER Sergey Ovechkin <me@pomeo.me>
ENV USER ubuntu
ENV NODE '5.1.0'

RUN ln -snf /bin/bash /bin/sh
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    supervisor \
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
    software-properties-common \
    openssh-server \
    sudo

RUN mkdir /var/run/sshd
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN useradd -ms /bin/bash $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'ubuntu:ubuntu' | chpasswd
USER $USER
WORKDIR /home/ubuntu

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
RUN cat /home/ubuntu/.nvm/nvm.sh >> /home/ubuntu/installnode.sh
RUN echo "nvm install $NODE" >> /home/ubuntu/installnode.sh
RUN sh installnode.sh
RUN sudo sed -i "s@.*PATH.*@PATH=\/home\/ubuntu\/.nvm\/versions\/node\/v$NODE\/bin:$PATH@" /etc/init.d/supervisor

RUN mkdir -p ~/www/logs

USER root

RUN echo "[group:app]" >> /etc/supervisor/conf.d/app.conf
RUN echo "programs=front" >> /etc/supervisor/conf.d/app.conf
RUN echo "[program:front]" >> /etc/supervisor/conf.d/app.conf
RUN echo "command=node app.js" >> /etc/supervisor/conf.d/app.conf
RUN echo "directory=/home/ubuntu/www/current/" >> /etc/supervisor/conf.d/app.conf
RUN echo "user=nobody" >> /etc/supervisor/conf.d/app.conf
RUN echo "autostart=true" >> /etc/supervisor/conf.d/app.conf
RUN echo "autorestart=true" >> /etc/supervisor/conf.d/app.conf
RUN echo "startretries=3" >> /etc/supervisor/conf.d/app.conf
RUN echo "stdout_logfile=/home/ubuntu/www/logs/server.log" >> /etc/supervisor/conf.d/app.conf
RUN echo "stdout_logfile_maxbytes=1MB" >> /etc/supervisor/conf.d/app.conf
RUN echo "stdout_logfile_backups=10" >> /etc/supervisor/conf.d/app.conf
RUN echo "stderr_logfile=/home/ubuntu/www/logs/error.log" >> /etc/supervisor/conf.d/app.conf
RUN echo "stderr_logfile_maxbytes=1MB" >> /etc/supervisor/conf.d/app.conf
RUN echo "stderr_logfile_backups=10" >> /etc/supervisor/conf.d/app.conf
RUN echo "stopsignal=TERM" >> /etc/supervisor/conf.d/app.conf
RUN echo "environment=NODE_ENV='production'" >> /etc/supervisor/conf.d/app.conf
RUN service supervisor restart

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
