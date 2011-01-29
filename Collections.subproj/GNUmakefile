# $Id: GNUmakefile,v 1.8 2004/01/26 18:52:11 marcel Exp $

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Collections

Collections_OBJC_FILES = \
	NSObjectFiltering.m		\
	NSArrayFiltering.m		\
	MPWRealArray.m			\
	MPWEnumFilter.m			\
	MPWUShortArray.m		\
	MPWSubData.m			\
	NSCaseInsensitiveUniqueString.m	\
	MPWEnumeratorEnumerator.m	\
	MPWEnumeratorSource.m		\
	MPWEnumeratorBase.m		\
	NSEnumeratorFiltering.m		\
	MPWUniqueString.m		\
	MPWFakedReturnMethodSignature.m \
	MPWIdentityDictionary.m \

ADDITIONAL_INCLUDE_DIRS = -I../.headers 
OBJCFLAGS = -fconstant-string-class=NSConstantString  -Wno-import -I../../

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble

