FROM gnustep-base


COPY install-gnustep-clang /
RUN chmod u+x install-gnustep-clang
RUN /install-gnustep-clang  

RUN useradd -ms /bin/bash gnustep

COPY bashrc /home/gnustep/.bashrc
COPY profile /home/gnustep/.profile
COPY bashrc /root/.bashrc
COPY profile /root/.profile
COPY bashrc /.bashrc
COPY profile /.profile


CMD ["bash"]

