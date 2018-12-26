FROM ubuntu

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
	vim build-essential  \
	clang llvm libblocksruntime-dev libkqueue-dev libpthread-workqueue-dev libxml2-dev cmake \
	libffi-dev \
	libreadline6-dev \
	libedit-dev \
	gnutls-dev 



CMD ["bash"]

