FROM gnustep-solid



COPY build-gnustep-clang /home/gnustep/
COPY patches/libobjc2-1.8.1/objcxx_eh.cc /home/gnustep/libobjc2-1.8.1/objcxx_eh.cc

RUN chmod u+x build-gnustep-clang
RUN /home/gnustep/build-gnustep-clang  

#USER gnustep
#WORKDIR /home/gnustep

CMD ["bash"]

