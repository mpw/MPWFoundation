/* MPWObjectCache.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWObject.h"
#import "AccessorMacros.h"
#import <pthread.h>


typedef long (*INT_IMP)(id, SEL );
typedef void (*VOID_IMP)(id, SEL, ...);



@interface MPWObjectCache : MPWObject  
{
@public
    IMP0		getObject;
}

+cacheWithCapacity:(int)newCap class:(Class)newClass;
-initWithCapacity:(int)newCap class:(Class)newClass;
-getObject;
-(void)makeThreadSafeOnDemand;
-(IMP)getObjectIMP;
-(void)clearCache;


boolAccessor_h( unsafeFastAlloc, setUnsafeFastAlloc )
scalarAccessor_h( SEL, reInitSelector, setReInitSelector )

#define	GETOBJECT( cache )		((cache)->getObject( (cache), @selector(getObject)))

//#define	GETOBJECT( cache )		([(cache) getObject])



#define CACHING_ALLOC( selector,size, unsafe  ) \
static pthread_key_t key=0;\
static void __objc_cache_destructor( void *objref )  { [(id)objref release]; }\
+selector\
{\
	if ( !key ) {\
		pthread_key_create(&key, __objc_cache_destructor);\
	}\
	MPWObjectCache *cache=pthread_getspecific( key  );\
	if ( !cache ) {\
/*        NSLog(@"will create a local cache for %@ for thread %p",NSStringFromClass(self),[NSThread currentThread]); */\
		cache = [[MPWObjectCache alloc] initWithCapacity:size class:self];\
		[cache setUnsafeFastAlloc:unsafe];\
		pthread_setspecific( key, cache );\
	}\
	return GETOBJECT(cache);\
}


@end
