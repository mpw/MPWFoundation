FROM ubuntu

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ 'Europe/Berlin'
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN apt-get update && apt-get install -y \
    gnustep-devel \
    git \
    make \
    ssh \
    inetutils-ping \
    llvm \
    clang \
	vim

RUN useradd -ms /bin/bash gnustep

COPY .bashrc /home/gnustep/
COPY .profile /home/gnustep/
COPY .bashrc /root/
COPY .profile /root/

#USER gnustep
#WORKDIR /home/gnustep

CMD ["bash"]

