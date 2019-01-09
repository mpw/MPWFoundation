FROM gnustep-solid



#USER gnustep
#WORKDIR /home/gnustep

COPY build-gnustep-clang /home/gnustep/build-gnustep-clang
RUN  mkdir -p /home/gnustep/patches/libobjc2-1.8.1/
COPY patches/libobjc2-1.8.1/objcxx_eh.cc /home/gnustep/patches/libobjc2-1.8.1/objcxx_eh.cc

RUN chmod u+x /home/gnustep/build-gnustep-clang
RUN /home/gnustep/build-gnustep-clang  

CMD ["bash"]

