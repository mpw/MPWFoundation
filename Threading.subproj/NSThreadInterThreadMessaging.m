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


#define HOM( msg  ) \
-msg { return [MPWTrampoline trampolineWithTarget:self selector:@selector(msg:)]; } \
-(void)msg:(NSInvocation*)invocation { \
//   invocation=(NSInvocation*)[MPWStackSaverInvocation withInvocation:invocation]; 



typedef void (^voidBlock)(void );

HOM( async )
#if NS_BLOCKS_AVAILABLE
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [invocation invokeWithTarget:self];});
#else    
    [invocation performSelectorInBackground:@selector(invokeWithTarget:) withObject:self];
#endif
}

#if NS_BLOCKS_AVAILABLE
HOM( asyncPrio )
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ [invocation invokeWithTarget:self];});
}

HOM( asyncBackground )
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{ [invocation invokeWithTarget:self];});
}
#endif

HOM(asyncOnMainThread)
	[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:NO];
}

HOM(syncOnMainThread)
	[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
}

-afterDelay:(NSTimeInterval)delay
{
	MPWTrampoline *trampoline=[MPWTrampoline trampolineWithTarget:self selector:@selector(invoke:afterDelay:)];
	[trampoline setXxxAdditionalArg:[NSNumber numberWithDouble:delay]];
	 return trampoline;
}

-(void)invoke:(NSInvocation*)anInvocation afterDelay:(NSNumber*)aDelay
{
	[anInvocation performSelector:@selector(invokeWithTarget:) withObject:self afterDelay:[aDelay doubleValue]];
}



@end
