# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = MPWFoundation

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build

include $(GNUSTEP_MAKEFILES)/common.make

libMPWFoundation_DLL_DEF = MPWFoundation.def

LIBRARY_NAME = libMPWFoundation


OBJCFLAGS += -Os -g -Wno-import


MPWFoundation_HEADER_FILES = \
	AccessorMacros.h		\
	CodingAdditions.h		\
	DebugMacros.h			\
	FIFO.h				\
	MPWASCII85Stream.h		\
	MPWAssociation.h		\
	MPWAsyncProxy.h			\
	MPWByteStream.h			\
	MPWEnumFilter.h			\
	MPWEnumSelectFilter.h		\
	MPWEnumeratorBase.h		\
	MPWEnumeratorEnumerator.h	\
	MPWEnumeratorSource.h		\
	MPWFakedReturnMethodSignature.h	\
	MPWFilterStream.h		\
	MPWFlattenStream.h		\
	MPWFoundation.h			\
	MPWHierarchicalStream.h		\
	MPWIgnoreTrampoline.h		\
	MPWJetStream.h			\
	MPWLZWStream.h			\
	MPWMsgExpression.h		\
	MPWObject.h			\
	MPWValueReference.h			\
	MPWObjectReference.h			\
	MPWObjectCache.h		\
	MPWPSByteStream.h		\
	MPWParallelStream.h		\
	MPWPoint.h			\
	MPWPropertyListStream.h		\
	MPWRealArray.h			\
	MPWRect.h			\
	MPWRuntimeAdditions.h		\
	MPWScanner.h			\
	MPWStream.h			\
	MPWSubData.h			\
	MPWTrampoline.h			\
	MPWUShortArray.h		\
	NSArrayFiltering.h		\
	NSArrayFilters.h		\
	NSBundleConveniences.h		\
	NSCaseInsensitiveUniqueString.h	\
	NSConditionLockSem.h		\
	NSDictAdditions.h		\
	NSEnumFilter.h			\
	NSEnumObjectFilter.h		\
	NSEnumeratorFiltering.h		\
	NSInvocationAdditions.h		\
	NSInvocationAdditions_lookup.h	\
	NSNil.h				\
	NSObjectAdditions.h		\
	NSObjectFiltering.h		\
	NSObjectInterThreadMessaging.h	\
	NSRectAdditions.h		\
	NSSelectEnumerator.h		\
	NSStringAdditions.h		\
	NSThreadInterThreadMessaging.h	\

MPWFoundation_HEADER_FILES_INSTALL_DIR = /MPWFoundation


libMPWFoundation_OBJC_FILES = \
    Stores.subproj/MPWAbstractStore.m \
	Stores.subproj/MPWEnsureNonNilStore.m \
	Stores.subproj/MPWPropertyPathStore.m \
    Stores.subproj/MPWDictStore.m \
    Stores.subproj/MPWDirectoryReference.m \
    Stores.subproj/MPWFileReference.m \
    Stores.subproj/MPWExtensionStore.m \
    Stores.subproj/MPWIdentifier.m \
    Stores.subproj/MPWReference.m \
    Stores.subproj/MPWValueReference.m \
    Stores.subproj/MPWGenericIdentifier.m \
    Stores.subproj/MPWTCPStore.m \
    Stores.subproj/MPWSFTPStore.m \
    Stores.subproj/MPWMappingStore.m \
    Stores.subproj/MPWCachingStore.m \
    Stores.subproj/MPWLoggingStore.m \
    Stores.subproj/MPWTemplateMatchingStore.m \
    Stores.subproj/MPWJSONConverterStore.m \
    Stores.subproj/MPWMergingStore.m \
    Stores.subproj/MPWPropertyStore.m \
    Stores.subproj/MPWInstanceVarStore.m \
    Stores.subproj/MPWRESTOperation.m \
    Stores.subproj/MPWSequentialStore.m \
    Stores.subproj/MPWReference.m \
    Stores.subproj/MPWPropertyBinding.m \
    Stores.subproj/MPWTCPBinding.m \
    Stores.subproj/MPWPathRelativeStore.m \
    Stores.subproj/MPWURLBasedStore.m \
    Stores.subproj/MPWURI.m \
    Stores.subproj/MPWDiskStore.m \
    Stores.subproj/MPWWriteBackCache.m \
    Stores.subproj/MPWURLSchemeResolver.m \
    Stores.subproj/MPWURLReference.m \
    Stores.subproj/MPWReferenceTemplate.m \
    Stores.subproj/MPWStreamableReference.m \
    Stores.subproj/MPWBasedStore.m \
    Streams.subproj/MPWDirectoryEnumerationStream.m \
    Streams.subproj/MPWIOURing.m \
    Streams.subproj/MPWPrintLiner.m \
    Streams.subproj/MPWByteStream.m \
    Streams.subproj/MPWLockedFilter.m \
    Streams.subproj/MPWFlattenStream.m \
    Streams.subproj/MPWStringTemplate.m \
    Streams.subproj/MPWArrayFlattenStream.m \
    Streams.subproj/MPWFilter.m \
    Streams.subproj/MPWFileChangesStreamLinux.m \
    Streams.subproj/MPWFixedValueSource.m \
    Streams.subproj/MPWWriteStream.m \
    Streams.subproj/MPWRESTCopyStream.m \
    Streams.subproj/MPWCombinerStream.m \
    Streams.subproj/MPWMapFilter.m \
    Streams.subproj/MPWEventWriter.m \
    Streams.subproj/MPWPipeline.m \
    Streams.subproj/MPWScatterStream.m \
    Streams.subproj/MPWActionStreamAdapter.m \
    Streams.subproj/MPWExternalFilter.m \
    Streams.subproj/MPWFDStreamSource.m \
    Streams.subproj/MPWStreamSource.m \
    Streams.subproj/MPWQueue.m \
    Streams.subproj/MPWSkipFilter.m \
    Streams.subproj/MPWBlockTargetStream.m \
    Streams.subproj/MPWBytesToLines.m \
    Streams.subproj/MPWURLCall.m \
    Streams.subproj/MPWURLStreamingStream.m \
    Streams.subproj/MPWURLFetchStream.m \
    Plist/MPWBinaryPListWriter.m \
    Plist/MPWNeXTPListWriter.m \
    Plist/MPWBinaryPlist.m \
    Plist/MPWPListBuilder.m \
    JSON/MPWMASONParser.m \
    JSON/MPWObjectBuilder.m \
    JSON/MPWConvertFromJSONStream.m \
    JSON/MPWJSONWriter.m \
    XML/MPWXmlScanner.m \
    XML/MPWXmlAppleProplistReader.m \
    XML/MPWMAXParser.m \
    XML/MPWXmlParser.m \
    XML/MPWXmlAttributes.m \
    XML/MPWXmlElement.m \
    XML/MPWXmlGeneratorStream.m \
    XML/MPWTagHandler.m \
    XML/MPWTagAction.m \
    Classes/MPWRuntimeAdditions.m \
    Classes/NSStringAdditions.m \
    Classes/NSDictAdditions.m \
    Classes/NSBundleConveniences.m \
    Classes/MPWRusage.m \
    Classes/NSNumberArithmetic.m \
    Classes/MPWInterval.m \
    Classes/MPWObject.m \
    Classes/MPWObjectCache.m \
    Classes/MPWFastInvocation.m \
    Classes/MPWTrampoline.m \
    Classes/MPWIgnoreUnknownTrampoline.m \
    Classes/MPWIgnoreTrampoline.m \
    Classes/MPWNumber.m \
    Classes/MPWInteger.m \
    Classes/MPWFloat.m \
    Classes/MPWPoint.m \
    Classes/MPWRect.m \
    Classes/MPWBlock.m \
    Classes/MPWCFunction.m \
    Classes/MPWBlockInvocable.m \
    Classes/MPWBoxerUnboxer.m \
    Classes/NSNil.m \
    Classes/MPWScanner.m \
    Classes/MPWBlockInvocation.m \
    Classes/MPWMessageCatcher.m \
    Classes/NSObjectAdditions.m \
    Classes/NSRunLoopAdditions.m \
    Classes/MPWResource.m \
    Threading.subproj/NSThreadInterThreadMessaging.m \
    Collections.subproj/MPWSmallStringTable.m \
    Collections.subproj/MPWCaseInsensitiveSmallStringTable.m \
    Collections.subproj/MPWIntArray.m \
    Collections.subproj/MPWRealArray.m \
    Collections.subproj/MPWSubData.m \
    Collections.subproj/NSObjectFiltering.m \
    Collections.subproj/MPWEnumFilter.m \
    Collections.subproj/MPWEnumSelectFilter.m \
    Collections.subproj/NSArrayFiltering.m \
    Markdown/MPWMarkdownTransformer.m \
    Markdown/NSDataMarkdown.m \
    GNUstep/ProtocolExtensions.m \


libMPWFoundation_C_FILES = \
    bytecoding.c \
    Markdown/autolink.c \
    Markdown/buffer.c \
    Markdown/houdini_href_e.c \
    Markdown/houdini_html_e.c \
    Markdown/html.c \
    Markdown/markdown.c \
    Markdown/stack.c \



MPWFoundation_SUBPROJECTS = \
	Collections.subproj	\
	Streams.subproj		\
	Comm.subproj		\


LIBRARIES_DEPEND_UPON += -lgnustep-base -lgnustep-corebase

# LDFLAGS += -L /C/GNUstep/System/Libraries/ix86/mingw32/gnu-gnu-gnu/ 


libMPWFoundation_INCLUDE_DIRS += -I.headers -I. -I..

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


test    : libMPWFoundation tester
	LD_LIBRARY_PATH=/usr/GNUstep/Local/Library/Libraries:/usr/local/lib:${HOME}/Build/obj/ ./GNUstep/testmpwfoundation

tester  :
	$(CC)  -fobjc-runtime=gnustep-2.1 -fblocks  -I/usr/GNUstep/Local/Library/Headers/ -I.headers -o GNUstep/testmpwfoundation GNUstep/testmpwfoundation.m -L/usr/GNUstep/Local/Library/Libraries/ -L ${HOME}/Build/obj -lMPWFoundation -lgnustep-base -lgnustep-corebase -L/usr/local/lib/ -lobjc
