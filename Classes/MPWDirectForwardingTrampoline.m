//
//  MPWDirectForwardingTrampoline.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 3/8/06.
/*
    Copyright (c) 2010 by Marcel Weiher. All rights reserved.

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

#import "MPWDirectForwardingTrampoline.h"
#import "MPWObjectCache.h"
#import "MPWRuntimeAdditions.h"
#import <objc/message.h>

#if !LINUX

@interface NSObject(forwardAMessage)

-forwardAMessage:anArg;

@end

@implementation MPWDirectForwardingTrampoline


CACHING_ALLOC( quickTrampoline, 5, YES )

#if 0
static id forwardAMessage( MPWDirectForwardingTrampoline* target, SEL _cmd,  ... )
{
//	NSLog(@"forwarding directly via va_list");
	va_list va;
	va_start( va, _cmd );
	return objc_msgSend( target->xxxTarget, target->xxxSelector ,_cmd ,va );
}
#endif



+ (BOOL)resolveInstanceMethod1:(SEL)sel
{
	Class cls = self;
	NSLog(@"installing forwarder");
	[cls addMethod:(IMP)[self instanceMethodForSelector:@selector(forwardAMessage:) ] forSelector:sel types: "@@#@"];
//	[NSObject aliasInstanceMethod:sel to:@selector(forwardAMessage:)  in:self];

//	class_addMethod(cls ,sel,(IMP)[self instanceMethodForSelector:@selector(forwardAMessage:)],"@@#@");
    return NO;
}


-(long long)forward:(SEL)selector :(id*)args
{
//	NSLog(@"forward::");
	objc_msgSend( xxxTarget, xxxSelector ,selector ,args ,0 );
	return 0LL;
}


@end

@implementation NSString(dummy_return_direct)

-dummy_return_direct:arg
{
    return @"bozo";
}


@end
@implementation MPWDirectForwardingTrampoline(testing)



+(void)testJump
{
    id obj=[self trampoline];
    NSString* result;
    [obj setXxxTarget:@"dummy_target"];
    [obj setXxxSelector:@selector(dummy_return_direct:)];
    result=[obj stringByAppendingString:@"hi"];
    NSAssert2( [result isEqual:@"bozo"],@"return '%@' unexpected, expected %@ ",result,@"bozo");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
//       @"testJump",
	    nil];
}

@end

#endif
