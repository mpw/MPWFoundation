/* MPWObjectCache.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

	Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the distribution.

	Neither the name Marcel Weiher nor the names of contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

*/


#import "MPWObject.h"
#import "AccessorMacros.h"
#import <pthread.h>


typedef long (*INT_IMP)(id, SEL );
typedef void (*VOID_IMP)(id, SEL, ...);



@interface MPWObjectCache : MPWObject  
{
    MPWObject   **objs;
    Class       objClass;
    SEL         allocSel,initSel;
    IMP0        allocImp,initImp,retainImp,autoreleaseImp;
    INT_IMP     retainCountImp;
    VOID_IMP    removeFromCacheImp;
    int         cacheSize;
    int         objIndex;
    void        *cachelock;
    BOOL        unsafeFastAlloc;
    VOID_IMP	releaseImp;
    SEL         reInitSelector;
    IMP0		reInitImp;
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
