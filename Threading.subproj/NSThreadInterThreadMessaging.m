/* NSThreadInterThreadMessaging.m Copyright (c) 1998-2011 by Marcel Weiher, All Rights Reserved.


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


NSString *NSThreadedObjectProxyAlreadyActiveException = @"NSThreadedObjectProxyAlreadyActiveException";



@implementation NSThread(InterThreadMessaging)
#if 0
static id _mainThread = nil;
+(void)load
{
    _mainThread = [self currentThread];
}
+mainThread
{
    return _mainThread;
}

+(BOOL)isMainThread
{
    return [self currentThread] == [self mainThread];
}
#endif

/*"
    InterThreadMessaging is a category of NSThread which simplifies
    the process of creating object %servers which respond to messages
    from within a predetermined thread.
    
    Consider a multithreaded application which includes an ApplicationKit
    based interface which must be messaged from within several independent
    threads of control performing calculations. The ApplicationKit is not
    threadsafe, so messages to it must be sent from the main thread of 
    control. InterThreadMessaging provides a solution to this problem:
    
    From within the main thread of control, objects can create a proxy
    for themselves or other objects that callers in other threads can
    retrieve:
    
    [NSThread createProxyForObjectInCurrentThread:%myButton];
    
    From the alternate thread, callers use the target object to retrieve
    a proxy, to which messages bound for the target may be sent:
    
    NSButton myProxy = [NSThread proxyForObject:myButton];
    [myProxy setTitle:@"a title"];
    
    When an object is no longer capable of being messaged or when
    it is to be freed, it must remove its proxy from the
    InterThreadMessaging proxy registry:
    
    [NSThread removeProxyForObject:%myButton];
"*/

    
static NSLock *lock = nil;
static NSMutableDictionary *handlers;

+ (id)allocateProxyForObject:(id)anObject
  /*" Returns the proxy created by a previous
  #createProxyForObjectInCurrentThread: message.

  Raises an NSInvalidArgumentException if anObject is nil.
  "*/
{
  id                  ret = nil;
  NSMutableDictionary *dict;

  NSParameterAssert(anObject != nil);

  [lock lock];
  dict = [handlers objectForKey:[NSValue valueWithPointer:anObject]];

  if (dict != nil) {
    NSConnection       *serverConnection;
    NSConnection       *clientConnection;

    serverConnection = [dict objectForKey:@"connection"];

    clientConnection = [[[NSConnection alloc]
                         initWithReceivePort:[serverConnection sendPort]
                         sendPort:[serverConnection receivePort]]
                        autorelease];

    ret = [clientConnection rootProxy];
  }
  [lock unlock];
  return ret;
}

+(BOOL)isInCurrentThread:anObject
  /*" Returns the proxy created by a previous
  #createProxyForObjectInCurrentThread: message.

  Raises an NSInvalidArgumentException if anObject is nil.
        */
{
  NSMutableDictionary *dict;

 BOOL ret=NO;
  NSParameterAssert(anObject != nil);

  [lock lock];
  dict = [handlers objectForKey:[NSValue valueWithPointer:anObject]];

  if (dict != nil) {
        ret = [[dict objectForKey:@"thread"]
isEqual:[self currentThread]];
  }
  [lock unlock];
  return ret;
}

static NSString *NSThreadProxyDict=@"NSThreadProxyDict";

-proxyDict
{
        id td,pd;

        td=[self threadDictionary];
        if ( nil == (pd=[td objectForKey:NSThreadProxyDict] ))
        {
                pd=[NSMutableDictionary dictionary];
                printf("will set proxydict\n");
                [td setObject:pd forKey:NSThreadProxyDict];
                printf("did set proxydict\n");
        }
        return pd;
}

-proxyForObject:anObject
{
        id dict,proxy,key;

        dict = [self threadDictionary];
        key=[NSValue valueWithPointer:anObject];

        if ( nil == (proxy=[dict objectForKey:key] ))
        {
            printf("will set local proxy\n");
                proxy=[[self class] allocateProxyForObject:anObject];
                [dict setObject:proxy forKey:key];
                printf("did set local proxy\n");
        }
        return proxy;
}

+currentThreadProxyForObject:anObject
{
        return [[self currentThread] proxyForObject:anObject];
}

+ (void)removeProxyForObject:(id)anObject
/*" Removes the proxy created by a previous
  #createProxyForObjectInCurrentThread: message.

  Raises an NSInvalidArgumentException if anObject is nil.
"*/
{
  NSParameterAssert(anObject != nil);
  [lock lock];
  [handlers removeObjectForKey:[NSValue valueWithPointer:anObject]];
  [lock unlock];
}

+ (BOOL)createServerForObjectInCurrentThread:(id)anObject
  /*" Creates a new proxy for anObject in the current thread. Callers using the
  proxy will cause messages to be sent to anObject from within the thread of
  execution active when this message is called. 

  Raises an NSInvalidArgumentException if anObject is nil. Raises an
  NSThreadedObjectProxyAlreadyActiveException if a proxy for the object
  is active for another thread of execution.
  "*/
{
  BOOL                ret = NO;
  NSException        *e = nil;

  NSParameterAssert(anObject != nil);

  if (lock == nil) {
    lock = [[NSLock alloc] init];
    handlers = [[NSMutableDictionary alloc] initWithCapacity:1];

  }

  [lock lock];

  if ([handlers objectForKey:[NSValue valueWithPointer:anObject]] == nil) {
    NSConnection       *serverConnection;
    NSDictionary       *dict;

    serverConnection = [[[NSConnection alloc]
                         initWithReceivePort:[NSPort port]
                         sendPort:[NSPort port]]
                        autorelease];

    [serverConnection setRootObject:anObject];

    dict = [[[NSDictionary alloc]
             initWithObjectsAndKeys:serverConnection, @"connection",
                                                        [self currentThread], @"thread", nil]
            autorelease];
    [handlers setObject:dict forKey:[NSValue valueWithPointer:anObject]];
  } else {
    e = [NSException exceptionWithName:NSThreadedObjectProxyAlreadyActiveException
         reason:@"a proxy for anObject is already active in another thread."
         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                   [NSThread currentThread], @"thread",
                   anObject, @"object",
                   handlers, @"handlers",
                   nil]];
  }

  [lock unlock];

  if (e != nil) {
    [e raise];
  }
  return ret;
}

+(void)runServerForObjectInCurrentThread:argArray
{
    id pool=[[NSAutoreleasePool alloc] init];
    id anObject=[argArray objectAtIndex:0];
    id cond = [argArray objectAtIndex:1];

    [self createServerForObjectInCurrentThread:anObject];
    [cond continue];
    [[NSRunLoop currentRunLoop] run];
    [pool release];
}

+ (void)createServerForObjectInNewThread:(id)anObject
{
    id cond=[NSConditionLock condition];
    [cond makeBlocking];
    [self detachNewThreadSelector:@selector(runServerForObjectInCurrentThread:)
                         toTarget:self
                       withObject:[NSArray arrayWithObjects:anObject,cond,nil]];
    [cond wait];
}

+(void)runInvocationInNewThread:(NSInvocation*)targetInvocation
{
	[self detachNewThreadSelector:@selector(exceptionPerformingInvocation:) toTarget:[targetInvocation target] withObject:targetInvocation];
}

@end


@implementation NSObject(threadingHOMs)

#define HOM( msg ) \
-msg { return [MPWTrampoline trampolineWithTarget:self selector:@selector(msg:)]; \
-msg:(NSInvocation*)invocation
	

-async
{
	return [MPWTrampoline trampolineWithTarget:self selector:@selector(runInvocationInThread:)];
}

-(void)runInvocationInThread:(NSInvocation*)invocation
{
	[invocation setTarget:self];
//	[invocation setReturnValue:&self];
	[NSThread runInvocationInNewThread:invocation];
}

-onMainThread
{
	
}


-afterDelay:(NSTimeInterval)delay
{
	
}



@end
