#!/bin/bash

set -x

# Show prompt function
function showPrompt()
{
  if [ "$PROMPT" = true ] ; then
    echo -e "\n\n"
    read -p "${GREEN}Press enter to continue...${NC}"
  fi
}

# Set colors
GREEN=`tput setaf 2`
NC=`tput sgr0` # No Color

# Set to true to also build and install apps
APPS=false

# Set to true to pause after each build to verify successful build and installation
PROMPT=false

# Install Requirements
sudo apt update

echo -e "\n\n${GREEN}Installing dependencies...${NC}"

sudo apt-get update
sudo apt -y install clang build-essential wget git subversion cmake libffi-dev libxml2-dev \
libgnutls28-dev libicu-dev libblocksruntime-dev libkqueue-dev libpthread-workqueue-dev autoconf libtool \
libjpeg-dev libtiff-dev libffi-dev libcairo-dev libx11-dev libxt-dev libxft-dev libxrandr-dev

if [ "$APPS" = true ] ; then
  sudo apt -y install curl
fi

# Create build directory
mkdir GNUstep-build
cd GNUstep-build

# Set clang as compiler
export CC=clang
export CXX=clang++
export CXXFLAGS="-std=c++11"
export RUNTIME_VERSION=gnustep-2.1
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export LD=/usr/bin/ld.gold
export LDFLAGS="-fuse-ld=/usr/bin/ld.gold -L/usr/local/lib"


# Checkout sources
echo -e "\n\n${GREEN}Checking out sources...${NC}"
git clone https://github.com/apple/swift-corelibs-libdispatch
# cd swift-corelibs-libdispatch
#   git checkout swift-5.5-RELEASE
# cd ..
git clone https://github.com/gnustep/libobjc2.git
cd libobjc2
  git submodule init
  git submodule sync
  git submodule update
cd ..
git clone https://github.com/gnustep/tools-make.git
git clone https://github.com/gnustep/libs-base.git
git clone https://github.com/gnustep/libs-corebase.git
git clone https://github.com/gnustep/libs-gui.git
git clone https://github.com/gnustep/libs-back.git

if [ "$APPS" = true ] ; then
  git clone https://github.com/gnustep/apps-projectcenter.git
  git clone https://github.com/gnustep/apps-gorm.git
  svn co http://svn.savannah.nongnu.org/svn/gap/trunk/libs/PDFKit/
  git clone https://github.com/gnustep/apps-gworkspace.git
  git clone https://github.com/gnustep/apps-systempreferences.git
fi

set -e
showPrompt

# Build GNUstep make first time
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-make for the first time...${NC}"
cd tools-make
# git checkout `git rev-list -1 --first-parent --before=2017-04-06 master` # fixes segfault, should probably be looked at.
#./configure --enable-debug-by-default --with-layout=gnustep  --enable-objc-arc  --with-library-combo=ng-gnu-gnu
  CC=$CC ./configure \
          --with-layout=gnustep \
              --disable-importing-config-file \
                  --enable-native-objc-exceptions \
                      --enable-objc-arc \
                          --enable-install-ld-so-conf \
                              --with-library-combo=ng-gnu-gnu

make -j8
sudo -E make install

. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh
echo ". /usr/GNUstep/System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc
echo "export RUNTIME_VERSION=$RUNTIME_VERSION" >> ~/.bashrc
echo 'export CXXFLAGS="-std=c++11"' >> ~/.bashrc


showPrompt

# Build libdispatch
echo -e "\n\n"
echo -e "${GREEN}Building libdispatch...${NC}"
cd ../swift-corelibs-libdispatch
rm -Rf build
mkdir build && cd build
cmake .. -DCMAKE_C_COMPILER=${CC} \
-DCMAKE_CXX_COMPILER=${CXX} \
-DCMAKE_BUILD_TYPE=Release \
-DUSE_GOLD_LINKER=YES
make
sudo -E make install
sudo ldconfig

showPrompt

# Build libobjc2
echo -e "\n\n"
echo -e "${GREEN}Building libobjc2...${NC}"
cd ../../libobjc2
rm -Rf build
mkdir build && cd build
cmake ../ -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_ASM_COMPILER=$CC -DTESTS=OFF
cmake --build .
sudo -E make install
sudo ldconfig

showPrompt

# Build GNUstep make second time
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-make for the second time...${NC}"
cd ../../tools-make
#./configure --enable-debug-by-default --with-layout=gnustep --enable-objc-arc --with-library-combo=ng-gnu-gnu
  CC=$CC ./configure \
          --with-layout=gnustep \
              --disable-importing-config-file \
                  --enable-native-objc-exceptions \
                      --enable-objc-arc \
                          --enable-install-ld-so-conf \
                              --with-library-combo=ng-gnu-gnu

make -j8
sudo -E make install

. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh

showPrompt

# Build GNUstep base
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-base...${NC}"
cd ../libs-base/
./configure
make -j8
sudo -E make install

showPrompt

# Build GNUstep corebase
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep corebase (set CFLAGS)...${NC}"
cd ../libs-corebase
CFLAGS=`gnustep-config --objc-flags` ./configure
make -j8
sudo -E make install
sudo ldconfig

showPrompt

echo -e "\n\n"
echo -e "${GREEN}Install is done. Open a new terminal to start using.${NC}"
