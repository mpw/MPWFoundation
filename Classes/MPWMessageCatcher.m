//
//  MPWMessageCatcher.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 24/10/2004.
/*  
    Copyright (c) 2004-2017 by Marcel Weiher.  All rights reserved.


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

#import "MPWMessageCatcher.h"
#import "DebugMacros.h"
#import "MPWObject.h"
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
#include <objc/message.h>
#endif

@implementation MPWMessageCatcher

-initWithClass:(Class)newClass
{
    if (self=[super init]) {
        messages=[[NSMutableArray alloc] init];
        testClass=newClass;
    }
    return self;
}

#if !WINDOWS && !LINUX
//extern id objc_msgSend(id, SEL, ...);

-(IMP)methodForSelector:(SEL)sel withDefault:(IMP)defaultMethod
{
	return (IMP)objc_msgSend;
}

#endif

-(BOOL)respondsToSelector:(SEL)aSelector
{
    return [testClass instancesRespondToSelector:aSelector] ||
			[object_getClass(self) instancesRespondToSelector:aSelector];
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature* sig;
	sig = [testClass instanceMethodSignatureForSelector:aSelector];
	if (!sig) {
		sig = [object_getClass(self) instanceMethodSignatureForSelector:aSelector];
	}
    return  sig;
}

-(void)forwardInvocation:(NSInvocation*)invocation
{
//	NSLog(@"add message: %@",invocation);
    [messages addObject:[[invocation copy] autorelease]];
	[[messages lastObject] retainArguments];
}

-(void)dealloc
{
    [messages release];
    [super dealloc];
//    NSDeallocateObject(self);
}

-(NSArray*)xxxMesssages
{
    return messages;
}

-(int)xxxMessageCount
{
    return [[self xxxMesssages] count];
}

-(NSInvocation*)xxxMessageAtIndex:(unsigned)anIndex
{
    return [[self xxxMesssages] objectAtIndex:anIndex];
}

-(NSString*)xxxMessageNameAtIndex:(unsigned)anIndex
{
    return NSStringFromSelector([[self xxxMessageAtIndex:anIndex] selector]);
}

-xxxMessageArgumentNumber:(unsigned)argIndex atIndex:(unsigned)messageIndex
{
    NSInvocation* message=[self xxxMessageAtIndex:messageIndex];
    id result;
    [message getArgument:&result atIndex:argIndex+2];
    return result;
}

@end

@interface MPWMessageCatcherTesting:NSObject {}
@end

@implementation MPWMessageCatcherTesting

+(void)testBasicCatch
{
    id catcher = [[[MPWMessageCatcher alloc] initWithClass:[NSArray class]] autorelease];
    INTEXPECT( [catcher xxxMessageCount],0 ,@"before first catch");
    [catcher objectAtIndex:0];
    INTEXPECT( [catcher xxxMessageCount],1,@"after first catch" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:0], @"objectAtIndex:", @"message name");
}

+(void)testShouldNotRespondToSelectorNotPartOfClass
{
    MPWMessageCatcher* catcher = [[[MPWMessageCatcher alloc] initWithClass:[NSArray class]] autorelease];
    EXPECTFALSE([catcher respondsToSelector:@selector(addObject:)], @"shouldn't respond to addObject:");
}

+(void)testMessageArgument
{
    id catcher = [[[MPWMessageCatcher alloc] initWithClass:[NSArray class]] autorelease];
    [catcher objectAtIndex:32];
    INTEXPECT( (NSUInteger)[catcher xxxMessageArgumentNumber:0 atIndex:0], 32, @"message argument");
}

+(NSArray*)testSelectors
{
#if WINDOWS
	return [NSArray array];
#else
    return [NSArray arrayWithObjects:
        @"testShouldNotRespondToSelectorNotPartOfClass",
        @"testBasicCatch",
        @"testMessageArgument",
        nil];
#endif
}

@end

