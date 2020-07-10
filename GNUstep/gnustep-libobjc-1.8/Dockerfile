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
	libmicrohttpd-dev \
	gnutls-dev 


RUN useradd -ms /bin/bash gnustep

COPY install-gnustep-clang /home/gnustep/
RUN chmod u+x /home/gnustep/install-gnustep-clang
RUN /home/gnustep/install-gnustep-clang  

COPY bashrc /home/gnustep/.bashrc
COPY profile /home/gnustep/.profile
COPY bashrc /root/.bashrc
COPY profile /root/.profile
COPY bashrc /.bashrc
COPY profile /.profile

COPY build-gnustep-clang /home/gnustep/build-gnustep-clang
RUN  mkdir -p /home/gnustep/patches/libobjc2-1.8.1/
COPY patches/libobjc2-1.8.1/objcxx_eh.cc /home/gnustep/patches/libobjc2-1.8.1/objcxx_eh.cc

RUN chmod u+x /home/gnustep/build-gnustep-clang
RUN /home/gnustep/build-gnustep-clang  


COPY build-gnustep-clang /home/gnustep/build-gnustep-clang
RUN  mkdir -p /home/gnustep/patches/libobjc2-1.8.1/
COPY patches/libobjc2-1.8.1/objcxx_eh.cc /home/gnustep/patches/libobjc2-1.8.1/objcxx_eh.cc

RUN chmod u+x /home/gnustep/build-gnustep-clang
RUN /home/gnustep/build-gnustep-clang  

CMD ["bash"]

