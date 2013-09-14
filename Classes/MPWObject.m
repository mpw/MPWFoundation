/* MPWObject.m Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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


//#define LOCKING

#import "MPWObject.h"
#import "MPWObject_fastrc.h"
#import <Foundation/Foundation.h>

#undef Darwin

#ifdef Rhapsody
#define CTHREADS 1
#endif
#ifdef GNUSTEP
#if !(defined(WIN32) || defined(_WIN32))
#define PTHREADS 1
#endif
#endif

#ifdef Darwin
#define CoreFoundation 1
#endif

#if CTHREADS
#import <mach/cthreads.h>
//int debug;
static mutex_t retain_lock=NULL;
#define LOCK(l)	if ( l != NULL ) mutex_lock(l)
#define UNLOCK(l) if ( l != NULL ) mutex_unlock(l)
#define INIT_LOCK(l)	if ( l == NULL ) { l = mutex_alloc(); }

#elif PTHREADS
#import <pthread.h>
#warning ---- pthreads ---
static pthread_mutex_t* retain_lock=NULL;
static pthread_mutex_t _the_lock;
#define LOCK(l)	if ( l != NULL ) pthread_mutex_lock(l)
#define UNLOCK(l) if ( l != NULL ) pthread_mutex_unlock(l)
#define INIT_LOCK(l)	if ( l == NULL ) { l = &_the_lock; pthread_mutex_init(l,NULL); }
#elif CoreFoundation

#include "SpinLocks.h"
#warning ---- spinlocks ---
static unsigned int *retain_lock=NULL;
static unsigned int _the_lock=0;
#ifndef _CFSpinLock
extern void __CFSpinLock( unsigned int *lock );
extern void __CFSpinUnlock( unsigned int *lock );
#endif
#define LOCK(l)	if ( l != NULL ) __CFSpinLock(l)
#define UNLOCK(l) if ( l != NULL ) __CFSpinUnlock(l)
#define INIT_LOCK(l)	if ( l == NULL ) { l = &_the_lock; _the_lock=0; }

#else
//#error no locking primitive!
#define LOCK(l)
#define UNLOCK(l)
#define INIT_LOCK(l)
#define INCREMENT( var )	var++;
#define DECREMENT( var )    var--;

#endif
/*
#else
//#error no locking primitive!
#define LOCK(l)
#define UNLOCK(l)
#define INIT_LOCK(l)
#include <libkern/OSAtomic.h>
#define INCREMENT( var )   (OSAtomicIncrement32(&var))
#define DECREMENT( var )   (OSAtomicDecrement32(&var))

#endif
*/
//#warning retainMPWObject
static int _collecting=NO;

#define MPWAssert1( expr, str, arg )  
//#define MPWAssert1( expr, str, arg )  if ( !(expr) ) { NSLog( str,arg);  }
//#define MPWAssert1( expr, str, arg )  if ( !(expr) ) { [NSException raise:@"assert" format:str,arg];  }

id retainMPWObject( MPWObject *obj )
{
	MPWAssert1( [obj isMPWObject] , @"trying to retainMPWObject a %@",[obj class]);
	if ( !_collecting ) {
		LOCK(retain_lock);
		INCREMENT( obj->_retainCount );
		UNLOCK(retain_lock);
	}
    return obj;
}
void retainMPWObjects( MPWObject **objs, unsigned count )
{
    int i;
	if ( !_collecting ) {
		LOCK(retain_lock);
		for (i=0;i<count;i++) {
			MPWAssert1( [objs[i] isMPWObject] , @"trying to retainMPWObject a %@",[objs[i]  class]);
			if ( objs[i] ) {
				INCREMENT( objs[i]->_retainCount );
			}
		}
	}
    UNLOCK(retain_lock);
}

void releaseMPWObject( MPWObject *obj )
{
    if ( obj && !_collecting ) {
		MPWAssert1( [obj isMPWObject] , @"trying to releaseMPWObject a %@",[obj  class]);
        LOCK(retain_lock);
        DECREMENT( obj->_retainCount);
        UNLOCK(retain_lock);
        if ( obj->_retainCount <0 ) {
            [obj dealloc];
        }
    }

}

void releaseMPWObjects( MPWObject **objs, unsigned count )
{
    if ( objs && !_collecting ) {
		int i;
		LOCK(retain_lock);
		for (i=0;i<count;i++) {
			if ( objs[i] ) {
				DECREMENT( objs[i]->_retainCount);
				if ( objs[i]->_retainCount < 0 ) {
					MPWAssert1( [objs[i] isMPWObject] , @"trying to releaseMPWObjects a %@",[objs[i]  class]);
					UNLOCK(retain_lock);
					[objs[i] dealloc];
					LOCK(retain_lock);
				}
			}
		}
		UNLOCK(retain_lock);
	}
}

@implementation NSObject(isMPWObject)

-(BOOL)isMPWObject { return NO; }

@end



@implementation MPWObject
/*"
     Provides a base object when fast reference counting is needed.
"*/

-(BOOL)isMPWObject { return YES; }

#if 0           // we no longer do this, I think...
+(void)initialize
{
    static BOOL inited=NO;
    if (!inited) {
        [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]
                     addObserver:self
                        selector:@selector(initializeThreaded)
                            name:NSWillBecomeMultiThreadedNotification
                          object:nil];
//		_collecting=IS_OBJC_GC_ON;
        inited=YES;
    }
}

+(void)initializeThreaded
{
    INIT_LOCK( retain_lock );
}
#endif 

+ alloc
{
    return (MPWObject *)NSAllocateObject(self, 0, NULL);
}

+ allocWithZone:(NSZone *)zone
{
    return (MPWObject *)NSAllocateObject(self, 0, zone);
}

- retain
{
    return retainMPWObject( self );
}

- (NSUInteger)retainCount
{
    return _retainCount+1;
}

- (oneway void)release
{
    releaseMPWObject(self);
}

-(NSString*)copyrightString
{
    return @"Copyright 1998-2012 by Marcel Weiher, All Rights Reserved.";
}

@end

#ifndef RELEASE
#import "DebugMacros.h"

@implementation MPWObject(testing)

+(void)retaintCountAfterAlloc
{
    id mpwobj=[[MPWObject alloc] init];
    id nsobj=[[NSObject alloc] init];
    INTEXPECT( [mpwobj retainCount], [nsobj retainCount] ,@"retaincount not equal after alloc");
    [nsobj release];
    [mpwobj release];
}

+(void)retainCountSameAsNSObject
{
    id mpo=[[[MPWObject alloc] init] autorelease],nso=[[[NSObject alloc] init] autorelease];
    INTEXPECT( [nso retainCount] , [mpo retainCount], @"retainCount of NSObject MPWObject");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
			@"retaintCountAfterAlloc",@"retainCountSameAsNSObject", nil];
}

@end

static int __globalCallDummy=0;
int ___crossModuleCallBenchmarkDoNothingFunction(int dummy1,int dummy2)
{
	__globalCallDummy++;
	return __globalCallDummy;
}

#endif
