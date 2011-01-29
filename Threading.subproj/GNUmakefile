# $Id: GNUmakefile,v 1.6 2004/01/07 16:38:43 marcel Exp $

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Threading

Threading_OBJC_FILES = \
	FIFO.m				\
	MPWAsyncProxy.m			\
	NSConditionLockSem.m		\
	NSObjectInterThreadMessaging.m	\
	NSThreadInterThreadMessaging.m	\

ADDITIONAL_INCLUDE_DIRS += -I. -I../.headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble
