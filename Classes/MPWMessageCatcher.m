//
//  MPWMessageCatcher.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 24/10/2004.
/*  
    Copyright (c) 2004-2017 by Marcel Weiher.  All rights reserved.
*/

#import "MPWMessageCatcher.h"
#import "DebugMacros.h"
#import <MPWObject.h>
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

-(long)xxxMessageCount
{
    return [[self xxxMesssages] count];
}

-(NSInvocation*)xxxMessageAtIndex:(int)anIndex
{
    return [[self xxxMesssages] objectAtIndex:anIndex];
}

-(NSString*)xxxMessageNameAtIndex:(int)anIndex
{
    return NSStringFromSelector([[self xxxMessageAtIndex:anIndex] selector]);
}

-xxxMessageArgumentNumber:(int)argIndex atIndex:(int)messageIndex
{
    NSInvocation* message=[self xxxMessageAtIndex:messageIndex];
    id result;
    [message getArgument:&result atIndex:argIndex+2];
    return result;
}

@end

#if GS_API_LATEST

@implementation NSInvocation(copy)

-copyWithZone:(NSZone*)zone
{
    return [self retain];
}

@end
#endif


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

