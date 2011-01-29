# $Id: GNUmakefile,v 1.7 2004/01/07 16:38:43 marcel Exp $

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Comm

Comm_OBJC_FILES = \
	MPWASCII85Stream.m	\
	MPWFilterStream.m	\
	MPWLZWStream.m		\
	MPWPSByteStream.m	\

#	MPWParallelStream.m	\
#	MPWJetStream.m		\

ADDITIONAL_INCLUDE_DIRS += -I. -I../.headers -I..

OBJCFLAGS=-fconstant-string-class=NSConstantString -Wno-import

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble
