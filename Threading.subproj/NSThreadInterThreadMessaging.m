/* NSThreadInterThreadMessaging.m Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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


#import "NSThreadInterThreadMessaging.h"
#import "NSConditionLockSem.h"
#import "MPWTrampoline.h"
#import <MPWFoundation/NSInvocationAdditions_lookup.h>
#if NS_BLOCKS_AVAILABLE
#include <dispatch/dispatch.h>
#endif
#import "MPWStackSaverInvocation.h"

NSString *NSThreadedObjectProxyAlreadyActiveException = @"NSThreadedObjectProxyAlreadyActiveException";



@implementation NSThread(InterThreadMessaging)



+(void)runInvocationInNewThread:(NSInvocation*)targetInvocation
{
	[self detachNewThreadSelector:@selector(exceptionPerformingInvocation:) toTarget:[targetInvocation target] withObject:targetInvocation];
}

@end

@implementation NSInvocation(invokeWithTargetInPool)

-(void)invokeWithTargetInPool:aTarget
{
	id pool=[NSAutoreleasePool new];
	[self invokeWithTarget:aTarget];
	[pool release];
}

@end



@implementation NSObject(threadingHOMs)

#define HOM_METHOD1( msg, type, conversion ) \
-msg:(type)arg  { id tramp = [MPWTrampoline trampolineWithTarget:self selector:@selector(msg:withArg:)]; [tramp setXxxAdditionalArg:conversion]; return tramp; } \
-(void)msg:(NSInvocation*)invocation withArg:arg { \

#define HOM_METHOD_DOUBLE( msg )    HOM_METHOD1( msg, double, [NSNumber numberWithDouble:arg] )



#define HOM_METHOD( msg  ) \
-msg { return [MPWTrampoline trampolineWithTarget:self selector:@selector(msg:)]; } \
-(void)msg:(NSInvocation*)invocation { \
//   invocation=(NSInvocation*)[MPWStackSaverInvocation withInvocation:invocation]; 



typedef void (^voidBlock)(void );


HOM_METHOD(asyncOnMainThread)
	[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:NO];
}

HOM_METHOD(onMainThread)
	[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
}
-(void)syncOnMainThread {  return [self onMainThread]; }


HOM_METHOD_DOUBLE( afterDelay )
	[invocation performSelector:@selector(invokeWithTarget:) withObject:self afterDelay:[arg doubleValue]];
}


HOM_METHOD1( asyncOn , dispatch_queue_t , (id)arg )
    SEL sel = [invocation selector];
    if ( sel && !strchr(sel_getName(sel), ':') ) {
        dispatch_async((dispatch_queue_t)arg, ^{ objc_msgSend(self,sel); });
    } else {
        dispatch_async((dispatch_queue_t)arg, ^{ [invocation invokeWithTarget:self];});
    }
}


HOM_METHOD1( syncOn  , dispatch_queue_t , (id)arg )
    SEL sel = [invocation selector];
    if ( sel && !strchr(sel_getName(sel), ':') ) {
        dispatch_sync((dispatch_queue_t)arg, ^{ objc_msgSend(self,sel); });
    } else {
        dispatch_sync((dispatch_queue_t)arg, ^{ [invocation invokeWithTarget:self];});
    }
}


-async {
    return [self asyncOn:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

-asyncPrio {
    return [self asyncOn:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
}

-asyncBackground {
    return [self asyncOn:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
}

HOM_METHOD1( asyncOnOperationQueue , id , arg )
    NSInvocationOperation *op=[[[NSInvocationOperation alloc] initWithInvocation:invocation] autorelease];
     [arg addOperation:op];
}

@end
