/* NSThreadInterThreadMessaging.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSThreadInterThreadMessaging.h"
#import "MPWTrampoline.h"
#import <MPWFoundation/NSInvocationAdditions_lookup.h>
#if NS_BLOCKS_AVAILABLE
#include <dispatch/dispatch.h>
#endif
#import "MPWStackSaverInvocation.h"
#import "MPWFastInvocation.h"
NSString *NSThreadedObjectProxyAlreadyActiveException = @"NSThreadedObjectProxyAlreadyActiveException";


#if ! TARGET_OS_IPHONE

@implementation NSThread(InterThreadMessaging)



+(void)runInvocationInNewThread:(NSInvocation*)targetInvocation
{
	[self detachNewThreadSelector:@selector(exceptionPerformingInvocation:) toTarget:[targetInvocation target] withObject:targetInvocation];
}

@end
#endif


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
-(void)msg:(NSInvocation*)invocation withArg:arg  \

#define HOM_METHOD_DOUBLE( msg )    HOM_METHOD1( msg, double, [NSNumber numberWithDouble:arg] )



#define HOM_METHOD( msg  ) \
-msg { return [MPWTrampoline trampolineWithTarget:self selector:@selector(msg:)]; } \
-(void)msg:(NSInvocation*)invocation  \
//   invocation=(NSInvocation*)[MPWStackSaverInvocation withInvocation:invocation]; 



typedef void (^voidBlock)(void );


HOM_METHOD(asyncOnMainThread)
{
    if ([NSThread isMainThread]) {
        [invocation invokeWithTarget:self];
    } else {
        [invocation retainArguments];
        [invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:NO];
    }
}

HOM_METHOD(syncOnMainThread)
{
    if ([NSThread isMainThread]) {
        [invocation invokeWithTarget:self];
    } else {
        [invocation retainArguments];
        [invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
    }
}

-onMainThread {  return [self asyncOnMainThread]; }


HOM_METHOD_DOUBLE( afterDelay )
{
	[invocation performSelector:@selector(invokeWithTarget:) withObject:self afterDelay:[arg doubleValue]];
}


HOM_METHOD1( asyncOn , dispatch_queue_t , (id)arg )
{
    SEL sel = [invocation selector];
    if ( sel && !strchr(sel_getName(sel), ':') ) {
        dispatch_async((dispatch_queue_t)arg, ^{ ((IMP0)objc_msgSend)(self,sel); });
    } else {
        dispatch_async((dispatch_queue_t)arg, ^{ [invocation invokeWithTarget:self];});
    }
}


HOM_METHOD1( syncOn  , dispatch_queue_t , (id)arg )
{
    SEL sel = [invocation selector];
    if ( sel && !strchr(sel_getName(sel), ':') ) {
        dispatch_sync((dispatch_queue_t)arg, ^{ ((IMP0)objc_msgSend)(self,sel); });
    } else {
        dispatch_sync((dispatch_queue_t)arg, ^{ [invocation invokeWithTarget:self];});
    }
}

HOM_METHOD1( onThread  , NSThread* , (id)arg )
{
    if ([NSThread currentThread] == arg) {
        [invocation invokeWithTarget:self];
    } else {
        [invocation retainArguments];
        [invocation performSelector:@selector(invokeWithTarget:) onThread:arg withObject:self waitUntilDone:NO];
    }
}

HOM_METHOD1( syncOnThread  , NSThread* , (id)arg )
{
    if ([NSThread currentThread] == arg) {
        [invocation invokeWithTarget:self];
    } else {
        [invocation retainArguments];
        [invocation performSelector:@selector(invokeWithTarget:) onThread:arg withObject:self waitUntilDone:YES];
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
{
    NSInvocationOperation *op=[[[NSInvocationOperation alloc] initWithInvocation:invocation] autorelease];
     [arg addOperation:op];
}



@end

#import <MPWFoundation/MPWWriteStream.h>

@implementation MPWWriteStream(sendmsg)


HOM_METHOD(sendmsg)
{
    NSLog(@"sendmsg with invocation: %@",invocation);
    [self writeObject:invocation];
}

@end
