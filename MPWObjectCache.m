/* MPWObjectCache.m Copyright (c) 1998-2011 by Marcel Weiher, All Rights Reserved.


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


#import "MPWObjectCache.h"

#import "NSInvocationAdditions_lookup.h"
#import <Foundation/Foundation.h>
#import <stdlib.h>

@implementation MPWObjectCache
/*"
   Provides a local, circular buffer for re-cycling objects.  Needs objects that can be
   re-initialized.  Can be made thread-safe if necessary, default is non-thread-safe
   because local allocators can be made thread-specific and thus avoid the locking
   overhead.

   The objects returned are usually retained+autoreleased and will not be re-used
   unless all external retains have been released.  This can be disabled for
   objects with known, limited lifetimes and caches large enough to avoid reallocation
   of the object while it is still in use.
 
"*/

static int _collecting=NO;

#ifdef IS_OBJC_GC_ON

+(void)initialize
{
	_collecting=IS_OBJC_GC_ON;
}

#endif

-initWithCapacity:(int)newCap class:(Class)newClass allocSel:(SEL)aSel initSel:(SEL)iSel
{
    self = [super init];
    allocSel=aSel;
    initSel=iSel;
    objClass = newClass;

    allocImp = [newClass methodForSelector:allocSel];
    NSAssert( allocImp != NULL , @"allocImp");
    initImp = [newClass instanceMethodForSelector:initSel];
    [self setReInitSelector:initSel];
    NSAssert( initImp != NULL , @"initImp");
    retainImp = [newClass instanceMethodForSelector:@selector(retain)];
    NSAssert( retainImp != NULL , @"retainImp");
    autoreleaseImp = [newClass instanceMethodForSelector:@selector(autorelease)];
    NSAssert( autoreleaseImp != NULL , @"autoreleaseImp");
    releaseImp = [newClass instanceMethodForSelector:@selector(release)];
    NSAssert( releaseImp != NULL , @"releaseImp");
    retainCountImp = [newClass instanceMethodForSelector:@selector(retainCount)];
    NSAssert( retainCountImp != NULL , @"retainCountImp");
	if ( [newClass instancesRespondToSelector:@selector(removeFromCache:)] ) {
		removeFromCacheImp=[newClass instanceMethodForSelector:@selector(removeFromCache:)];
	} else {
		removeFromCacheImp=NULL;
	}
    objs = calloc( newCap+2, sizeof *objs);
    cacheSize = newCap;
    getObject = [self getObjectIMP];
    return self;
}

+cacheWithCapacity:(int)newCap class:(Class)newClass
{
    return [[[self alloc] initWithCapacity:newCap class:newClass] autorelease];
}

-initWithCapacity:(int)newCap class:(Class)newClass
{
    return [self initWithCapacity:newCap class:newClass allocSel:@selector(alloc)
                          initSel:@selector(init)];
}

-(void)makeThreadSafeNow
/*"
     Make the object cache thread-safe by providing locks around getObject calls.
"*/
{
//    cachelock=mutex_alloc( );
}

-(void)makeThreadSafeOnDemand
/*"
    Make the object cache thread-safe if the process becomes multi-threaded.
"*/
{
    [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]
                 addObserver:self
                    selector:@selector(makeThreadSafeNow)
                        name:NSWillBecomeMultiThreadedNotification
                      object:nil];    
}

-(IMP)getObjectIMP
/*"
    Return a pointer to the method getObject for fast calls to the allocator.
"*/
{
	[self getObject];
    return [self methodForSelector:@selector(getObject)];
}

boolAccessor( unsafeFastAlloc, setUnsafeFastAlloc )
scalarAccessor( SEL, reInitSelector, _setReInitSelector )

-(void)setReInitSelector:(SEL)newSelector
{
    [self _setReInitSelector:newSelector];
    reInitImp = [objClass instanceMethodForSelector:newSelector];
    NSAssert( reInitImp != NULL , @"reInitImp");
}

#if  SLOW_SAMPLE_IMPLEMENTATION_WANTED
-getObject
{
    id obj;
    objIndex++;
    if ( objIndex >= cacheSize ) {
        objIndex=0;
    }
    obj=objs[objIndex];
    if ( obj==nil ||  [obj retainCount] > 1 ) {
        if ( obj!=nil ) {
            [obj release];
			//--- removeFromCache 
        }
        obj = [[objClass alloc] init];
        objs[objIndex]=obj;
    }
    return [[obj retain] autorelease];
}
#else

static int misses=0,hits=0;
intAccessor( misses, setMisses)
intAccessor( hits, setHits )

-getObject
/*"
    Returns an object as if freshly allocated.
"*/
{
	if (_collecting) {
		return initImp( allocImp( objClass, allocSel ),initSel);
	} else {
		int i,maxIndex;
		MPWObject *obj=nil;
	//	look back just a bit, a lot can be stacking order
		objIndex++;
		if ( cachelock ) {
//        mutex_lock( (mutex_t)cachelock );
		}
		if ( objIndex >= cacheSize ) {
			objIndex=0;
		}
		for (i=objIndex,maxIndex=MIN(objIndex+4,cacheSize);i<maxIndex;i++) {
			obj=objs[i];
			if ( obj != nil ) {
				if ((int)retainCountImp( obj, @selector(retainCount)) <= 1 ) {
					break;
				} else {
					obj=nil;
				}
			}
		}
		if ( obj == nil ) {
			obj=objs[objIndex];
			misses++;
			if ( obj!=nil ) {
				releaseImp( objs[objIndex] ,@selector(release));
				if ( removeFromCacheImp ) {
	//				NSLog(@"remove from cache");
					removeFromCacheImp( objs[objIndex] ,@selector(removeFromCache:), self );
				}
			}
	//		NSLog(@"had to (re)alloc %@/%dm hits:%d misses:%d rate: %d",obj,[obj retainCount],hits,misses,hits*100/(hits+misses));
			objs[objIndex] = initImp( allocImp( objClass, allocSel ),initSel);
			obj=objs[objIndex];
		} else {
			hits++;
	//		NSLog(@"found after %d probes",i-objIndex);
			objIndex=i;
		}
		if ( cachelock ) {
	//        mutex_unlock( (mutex_t)cachelock );
		}
		if ( unsafeFastAlloc &&!cachelock) {
			return obj;
			//        return initImp( obj, initSel);
		} else {
			return autoreleaseImp( retainImp(obj,@selector(retain)), @selector(autorelease) );
		}
	}
}
#endif

-(void)clearCache
{
	int i;
    if ( objs ) {
        for (i=0;i<cacheSize;i++) {
            if ( objs[i] ) {
				if ( removeFromCacheImp && [objs[objIndex] retainCount] > 1 ) {
//					NSLog(@"remove from cache");
					removeFromCacheImp( objs[objIndex] ,@selector(removeFromCache:), self );
				}
                releaseImp( objs[i] ,@selector(release));
				objs[i]=nil;
            }
        }
    }

}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]
                 removeObserver:self];
    if ( objs ) {
		[self clearCache];
        free(objs);
    }
    if (cachelock) {
//        mutex_free( (mutex_t)cachelock );
    }
    [super dealloc];
}

-description
{
	return [NSString stringWithFormat:@"<%@:%p: class: %@ getObject: %p/%p  >",
			[self class],self,objClass,[self getObjectIMP],getObject];
}

@end

