# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = interscript

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = interscript


OBJCFLAGS += -g -Os -Wno-import `pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1` 


interscript_HEADER_FILES = \


interscript_HEADER_FILES_INSTALL_DIR = /stsh


interscript_OBJC_FILES = \
	Classes/ISWebRunner.m \


interscript_C_FILES = \




LIBRARIES_DEPEND_UPON += -lMPWFoundation -lgnustep-base

LDFLAGS += -L ${HOME}/Build/obj 


interscript_INCLUDE_DIRS += -I.headers -I. -I ../../.headers/ -I../.headers/

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

before-all ::
	
#	@$(MKDIRS) $(libMPWFoundation_HEADER_FILES_DIR)
#	cp *.h $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Collections.subproj/*.h $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Comm.subproj/*.h        $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Streams.subproj/*.h     $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Threading.subproj/*.h   $(libMPWFoundation_HEADER_FILES_DIR)

after-clean ::
	rm -rf .headers


webview  : webview.m
	$(CC) -g -fobjc-runtime=gnustep-2.1  -fblocks -IClasses -I/usr/GNUstep/Local/Library/Headers/  -I../../.headers/ -I.headers `pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1`  -o webview webview.m -L ${HOME}/Build/obj -L/usr/GNUstep/Local/Library/Libraries -lMPWFoundation -lgnustep-base -lgnustep-corebase -L/usr/local/lib/ -lobjc  -lgtk-3 -lgobject-2.0 -lwebkit2gtk-4.1  

