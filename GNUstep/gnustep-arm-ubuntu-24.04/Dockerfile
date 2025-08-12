FROM ubuntu:24.04

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ 'Europe/Berlin'
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN apt-get update && apt-get install -y \
    git \
    make \
    ssh \
    sudo \
    curl \
    inetutils-ping \
    clang \
    libssl-dev \
    pkg-config \
	vim build-essential  \
	libreadline6-dev \
	libedit-dev \
	libmicrohttpd-dev


RUN useradd -ms /bin/bash gnustep

COPY bashrc /home/gnustep/.bashrc
COPY profile /home/gnustep/.profile
COPY bashrc /root/.bashrc
COPY profile /root/.profile
COPY bashrc /.bashrc
COPY profile /.profile

COPY GNUstep-buildon-ubuntu2024_arm.sh  /home/gnustep/GNUstep-buildon-ubuntu2024_arm.sh
COPY build-corebase.sh /home/gnustep/build-corebase.sh
RUN chmod u+x /home/gnustep/GNUstep-buildon-ubuntu2024_arm.sh
RUN chmod u+x /home/gnustep/build-corebase.sh
RUN /home/gnustep/GNUstep-buildon-ubuntu2024_arm.sh  
RUN /home/gnustep/build-corebase.sh

CMD ["bash"]

