FROM gnustep-base


RUN apt-get install -y llvm

COPY install-gnustep-clang /
RUN chmod u+x install-gnustep-clang
RUN /install-gnustep-clang  

RUN useradd -ms /bin/bash gnustep

COPY .bashrc /home/gnustep/
COPY .profile /home/gnustep/
COPY .bashrc /root/
COPY .profile /root/

#USER gnustep
#WORKDIR /home/gnustep

CMD ["bash"]

