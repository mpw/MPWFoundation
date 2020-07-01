/* MPWObjectCache.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWObjectCache.h"

#import "NSInvocationAdditions_lookup.h"
#import <Foundation/Foundation.h>
#import <stdlib.h>

@interface NSObject(removeFromCache)

-(void)removeFromCache:(MPWObjectCache*)aCache;

@end

@implementation MPWObjectCache
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

}
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


-(void)setInitIMP:(IMP0)newImp
{
    initImp=newImp;
}

-initWithCapacity:(int)newCap class:(Class)newClass allocSel:(SEL)aSel initSel:(SEL)iSel
{
    self = [super init];
    allocSel=aSel;
    initSel=iSel;
    objClass = newClass;

    allocImp = (IMP0)[newClass methodForSelector:allocSel];
    NSAssert( allocImp != NULL , @"allocImp");
    [self setReInitSelector:initSel];
//    NSAssert( initImp != NULL , @"initImp");
    retainImp = (IMP0)[newClass instanceMethodForSelector:@selector(retain)];
    NSAssert( retainImp != NULL , @"retainImp");
    autoreleaseImp = (IMP0)[newClass instanceMethodForSelector:@selector(autorelease)];
    NSAssert( autoreleaseImp != NULL , @"autoreleaseImp");
    releaseImp = (VOID_IMP)[newClass instanceMethodForSelector:@selector(release)];
    NSAssert( releaseImp != NULL , @"releaseImp");
    retainCountImp = (INT_IMP)[newClass instanceMethodForSelector:@selector(retainCount)];
    NSAssert( retainCountImp != NULL , @"retainCountImp");
	if ( [newClass instancesRespondToSelector:@selector(removeFromCache:)] ) {
		removeFromCacheImp=(VOID_IMP)[newClass instanceMethodForSelector:@selector(removeFromCache:)];
	} else {
		removeFromCacheImp=NULL;
	}
    objs = calloc( newCap+2, sizeof *objs);
    cacheSize = newCap;
    getObject = (IMP0)[self getObjectIMP];
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
//	[self getObject];
    return [self methodForSelector:@selector(getObject)];
}

boolAccessor( unsafeFastAlloc, setUnsafeFastAlloc )
scalarAccessor( SEL, reInitSelector, _setReInitSelector )

-(void)setReInitSelector:(SEL)newSelector
{
    [self _setReInitSelector:newSelector];
    reInitImp = (IMP0)[objClass instanceMethodForSelector:newSelector];
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
    {
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

            // lazy fetch of initImp needed for some class clusters
            // that substitute instances of a different classs
            // (so IMP from original class won't work for actual instance
            //  created).

            id allocated = allocImp( objClass, allocSel );
            if (!initImp) {
                allocated=((IMP0)objc_msgSend)(allocated, reInitSelector);
                initImp = (IMP0)[allocated methodForSelector:initSel];
            } else {
                allocated=initImp(allocated ,initSel);

            }
			objs[objIndex] = allocated;
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


-new
{
    return [self getObject];
}

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

#import "DebugMacros.h"

@implementation MPWObjectCache(testing)

+(void)testCanCreateMutableDictionary
{
    MPWObjectCache *cache=[self cacheWithCapacity:2 class:[NSMutableDictionary class]];
    NSMutableDictionary *d=GETOBJECT(cache);
    INTEXPECT(d.count, 0, @"count of dict after create");
    d[@"hi"]=@"there";
    INTEXPECT(d.count, 1, @"count of dict after set");
    IDEXPECT(d[@"hi"], @"there",@"value we put in");
}

+(NSArray<NSString*>*)testSelectors
{
    return @[
        @"testCanCreateMutableDictionary",
    ];
}

@end
