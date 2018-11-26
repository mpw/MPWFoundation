//
//  MPWDirectForwardingTrampoline.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 3/8/06.
/*
    Copyright (c) 2010 by Marcel Weiher. All rights reserved.

R

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


//-(long long)forward:(SEL)selector :(id*)args
//{
////    NSLog(@"forward::");
//    ((IMP0)objc_msgSend)( xxxTarget, xxxSelector ,selector ,args ,0 );
//    return 0LL;
//}
//

@end

@implementation NSString(dummy_return_direct)

-_dummy_return_direct:arg
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
    [obj setXxxSelector:@selector(_dummy_return_direct:)];
    result=[obj stringByAppendingString:@"hi"];
    NSAssert2( [result isEqual:@"bozo"],@"return '%@' unexpected, expected %@ ",result,@"bozo");
}


+testSelectors
{
    return @[
//       @"testJump",
	    ];
}

@end

#endif
