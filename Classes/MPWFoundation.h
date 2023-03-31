/* MPWFoundation.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/CodingAdditions.h>
#import <MPWFoundation/DebugMacros.h>
#import <MPWFoundation/MPWObject.h>
#import <MPWFoundation/NSInvocationAdditions.h>
#import <MPWFoundation/MPWFastInvocation.h>
#import <MPWFoundation/MPWObjectCache.h>
#import <MPWFoundation/MPWBlockInvocation.h>
#import <MPWFoundation/MPWRusage.h>
#import <MPWFoundation/MPWMessageCatcher.h>
#import <MPWFoundation/MPWBoxerUnboxer.h>
#import <MPWFoundation/MPWRuntimeAdditions.h>
#import <MPWFoundation/MPWMsgExpression.h>
#import <MPWFoundation/NSStringAdditions.h>
#import <MPWFoundation/NSObjectAdditions.h>
#import <MPWFoundation/MPWNumber.h>
#import <MPWFoundation/MPWInterval.h>
#import <MPWFoundation/MPWFloat.h>
#import <MPWFoundation/MPWInteger.h>
#import <MPWFoundation/MPWPropertyBinding.h>
#import <MPWFoundation/NSRunLoopAdditions.h>
#import <MPWFoundation/MPWObject_fastrc.h>
#import <MPWFoundation/MPWResource.h>

#import <MPWFoundation/MPWBlockInvocable.h>
#import <MPWFoundation/NSNil.h>



#import <MPWFoundation/MPWWriteStream.h>
#import <MPWFoundation/MPWStreamSource.h>
#import <MPWFoundation/MPWFilter.h>
#import <MPWFoundation/MPWArrayFlattenStream.h>
#import <MPWFoundation/MPWFlattenStream.h>
#import <MPWFoundation/MPWByteStream.h>
#import <MPWFoundation/MPWPipeline.h>
#import <MPWFoundation/MPWThreadSwitchStream.h>
#import <MPWFoundation/MPWConvertFromJSONStream.h>
#import <MPWFoundation/MPWJSONWriter.h>
#import <MPWFoundation/MPWObjectCreatorStream.h>
#import <MPWFoundation/MPWURLFetchStream.h>
#import <MPWFoundation/MPWURLStreamingStream.h>
#import <MPWFoundation/MPWASCII85Stream.h>
#import <MPWFoundation/MPWURLCall2StoreStream.h>
#import <MPWFoundation/MPWNotificationStream.h>
#import <MPWFoundation/MPWDistributedNotificationStream.h>
#import <MPWFoundation/MPWDistributedNotificationReceiver.h>
#import <MPWFoundation/MPWMapFilter.h>
#import <MPWFoundation/MPWQueue.h>

#import <MPWFoundation/MPWBlockTargetStream.h>
#import <MPWFoundation/MPWCombinerStream.h>
#import <MPWFoundation/MPWDelayStream.h>
#import <MPWFoundation/MPWURLCall.h>
#import <MPWFoundation/MPWSocketStream.h>
#import <MPWFoundation/MPWScatterStream.h>
#import <MPWFoundation/MPWActionStreamAdapter.h>
#import <MPWFoundation/MPWBinaryPListWriter.h>
#import <MPWFoundation/MPWPListBuilder.h>
#import <MPWFoundation/MPWLZWStream.h>
#import <MPWFoundation/MPWFDStreamSource.h>
#import <MPWFoundation/MPWExternalFilter.h>
#import <MPWFoundation/MPWRESTCopyStream.h>
#import <MPWFoundation/MPWSkipFilter.h>
#import <MPWFoundation/MPWExtensionAdder.h>

#import <MPWFoundation/NSThreadWaiting.h>
#import <MPWFoundation/MPWFuture.h>
#import <MPWFoundation/MPWTrampoline.h>
#import <MPWFoundation/MPWIgnoreTrampoline.h>
#import <MPWFoundation/NSObjectFiltering.h>
#import <MPWFoundation/MPWEnumeratorEnumerator.h>
#import <MPWFoundation/MPWEnumeratorSource.h>
#import <MPWFoundation/MPWRealArray.h>
#import <MPWFoundation/MPWUShortArray.h>
#import <MPWFoundation/MPWFakedReturnMethodSignature.h>
#import <MPWFoundation/MPWKVCSoftPointer.h>
#import <MPWFoundation/MPWSoftPointerProxy.h>
#import <MPWFoundation/NSArrayFiltering.h>

#if !__has_feature(objc_arc)
#import <MPWFoundation/MPWObjectCache.h>
#endif

#import <MPWFoundation/MPWSubData.h>
#import <MPWFoundation/MPWBinaryPlist.h>
#import <MPWFoundation/MPWDelimitedTable.h>
#import <MPWFoundation/MPWSmallStringTable.h>
#import <MPWFoundation/MPWCaseInsensitiveSmallStringTable.h>
#import <MPWFoundation/MPWScanner.h>
#import <MPWFoundation/MPWPoint.h>
#import <MPWFoundation/MPWRect.h>
#import <MPWFoundation/NSDictAdditions.h>
#import <MPWFoundation/MPWIdentityDictionary.h>
#import <MPWFoundation/MPWObjectReference.h>

#import <MPWFoundation/NSThreadInterThreadMessaging.h>
#import <MPWFoundation/bytecoding.h>
#import <MPWFoundation/NSRectAdditions.h>
#import <MPWFoundation/NSBundleConveniences.h>
#import <MPWFoundation/MPWIntArray.h>
#import <MPWFoundation/NSNumberArithmetic.h>

#import <MPWFoundation/NSObject+MPWNotificationProtocol.h>

#import <MPWFoundation/MPWAbstractStore.h>
#import <MPWFoundation/MPWBinding.h>
#import <MPWFoundation/MPWCachingStore.h>
#import <MPWFoundation/MPWCompositeStore.h>
#import <MPWFoundation/MPWDictStore.h>
#import <MPWFoundation/MPWDiskStore.h>
#import <MPWFoundation/MPWGenericReference.h>
#import <MPWFoundation/MPWLoggingStore.h>
#import <MPWFoundation/MPWMappingStore.h>
#import <MPWFoundation/MPWMergingStore.h>
#import <MPWFoundation/MPWNameRemappingStore.h>
#import <MPWFoundation/MPWPathRelativeStore.h>
#import <MPWFoundation/MPWReference.h>
#import <MPWFoundation/MPWSequentialStore.h>
#import <MPWFoundation/MPWSwitchingStore.h>
#import <MPWFoundation/MPWURLBasedStore.h>
#import <MPWFoundation/MPWURLReference.h>
#import <MPWFoundation/MPWWriteBackCache.h>
#import <MPWFoundation/MPWDirectoryBinding.h>
#import <MPWFoundation/MPWFileBinding.h>
#import <MPWFoundation/MPWPropertyStore.h>
#import <MPWFoundation/MPWTCPStore.h>
#import <MPWFoundation/MPWTCPBinding.h>
#import <MPWFoundation/MPWURLSchemeResolver.h>
#import <MPWFoundation/MPWSFTPStore.h>
#import <MPWFoundation/MPWStreamableBinding.h>


#import <MPWFoundation/MPWXmlGeneratorStream.h>
#import <MPWFoundation/MPWMASONParser.h>
#import <MPWFoundation/MPWObjectBuilder.h>

#if !GS_API_LATEST
#import <MPWFoundation/MPWStreamQLite.h>
#endif
