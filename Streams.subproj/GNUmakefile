# $Id: GNUmakefile,v 1.7 2004/01/07 16:38:43 marcel Exp $

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Streams

Streams_OBJC_FILES = \
	MPWByteStream.m		\
	MPWFlattenStream.m	\
	MPWHierarchicalStream.m	\
	MPWPropertyListStream.m	\
	MPWStream.m		\

ADDITIONAL_INCLUDE_DIRS += -I. -I../.headers -I..
OBJCFLAGS = -fconstant-string-class=NSConstantString -Wno-import

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble
