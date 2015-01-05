/* MPWAsyncProxy.m Copyright (c) 1998-2015 by Marcel Weiher, All Rights Reserved.


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


#import "MPWAsyncProxy.h"
#import "NSThreadInterThreadMessaging.h"

@implementation MPWAsyncProxy

-initWithDelegate:newDel
{
//    [super init];
    delegate=[newDel retain];
    proxy=[self proxyForServerInNewThread];
    //    lock=[NSLock lock];
    return self;
}

-(void)makeServerInCurrentThread
{
        [NSThread createServerForObjectInCurrentThread:self];
}

-(void)makeServerInNewThread
{
        [NSThread createServerForObjectInNewThread:self];
}


-currentThreadProxy
{
        return [NSThread currentThreadProxyForObject:self];
}

-(id)proxyForServerInNewThread
{
        [self makeServerInNewThread];
        return [self currentThreadProxy];
}


-(void)removeProxy
{
        [NSThread removeProxyForObject:self];
}



-(void oneway)asyncForward:(void*)anInvocation
{
    NSInvocation *inv=anInvocation;
    [inv setTarget:delegate];
    [inv invoke];
    
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)sel
{
    return [delegate methodSignatureForSelector:sel];
}

-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    printf("forward called for %s\n",[NSStringFromSelector([anInvocation selector]) cString]);
    [proxy asyncForward:(void*)anInvocation];
/*
   [NSThread detachNewThreadSelector:
        @selector(asyncForward:)
                         toTarget:self
                         withObject:anInvocation];
*/
    //  [[self proxyForServerInNewThread] asyncForward:(void*)anInvocation];
}
@end


@implementation NSObject(Asyncing)

-asyncProxy
{
    return [[MPWAsyncProxy alloc] initWithDelegate:self];
}

@end

