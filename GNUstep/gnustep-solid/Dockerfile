FROM gnustep-base



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


CMD ["bash"]

