//
//  MPWIgnoreUnknownTrampoline.m
//  MPWFoundation
//
/*
    Copyright (c) 2005-2012 by Marcel Weiher. All rights reserved.

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

//

#import "MPWIgnoreUnknownTrampoline.h"
#import "NSInvocationAdditions.h"
#import "MPWObjectCache.h"

@implementation MPWIgnoreUnknownTrampoline

CACHING_ALLOC( quickTrampoline, 5, YES )


-(void)doesNotRecognizeSelector:(SEL)selector
{
	NSLog(@"MPWIgnoreUnknownTrampoline -doesNotRecognizeSelector");
}

+(void)doesNotRecognizeSelector:(SEL)selector
{
	NSLog(@"MPWIgnoreUnknownTrampoline +doesNotRecognizeSelector");
}

+(BOOL)respondsToSelector:(SEL)aSelector
{
//	NSLog(@"respondsToSelector");
    return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *sig;
//	NSLog(@"method signature for selector");
    sig = [[self sendTarget] methodSignatureForSelector:aSelector];
    if (!sig ) {
        sig = [NSObject methodSignatureForSelector:@selector(class)];
    }
    return sig;
}


@end


@implementation NSObject(sendIfResponds)


-sendIfResponds:(NSInvocation*)invocation
{
    id retval=nil;
    if ( [self respondsToSelector:[invocation selector]]) {
        retval =[invocation returnValueAfterInvokingWithTarget:self];
    }
    return retval;
}

-sendIfResponds
{
    id trampoline = [MPWIgnoreUnknownTrampoline trampolineWithTarget:self selector:@selector(sendIfResponds:)];
	return trampoline;
}

@end

@interface MPWIgnoreUnknownTrampolineTesting : NSObject {} @end
@interface NSString(doesntReallyRespondToStringValue1)
-stringValue1;
@end

@implementation MPWIgnoreUnknownTrampolineTesting

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"testSendIfResponds", nil];
}


+(void)testSendIfResponds
{
    id a = @"John Doe";
    id  str = [a stringValue];
    IDEXPECT( str, a ,@"safely sending should yield same value if exists" );
    [[a sendIfResponds] stringValue1];
}



@end
