//
//  MPWFastInvocation.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 27/3/07.
//  Copyright 2010-2011 by Marcel Weiher. All rights reserved.
//

#import "MPWFastInvocation.h"
#import "DebugMacros.h"
#import "AccessorMacros.h"
#import "NSInvocationAdditions_lookup.h"
#if FULL_MPWFOUNDATION && !WINDOWS && !LINUX
#import "MPWRusage.h"
#endif

@implementation MPWFastInvocation


scalarAccessor( id, target, _setTarget )
idAccessor( result, setResult )
boolAccessor( useCaching, _setUseCaching )

// extern id objc_msgSend( id receiver, SEL _cmd, ... );

-init
{
	self = [super init];
	invokeFun=[self methodForSelector:@selector(resultOfInvoking)];
	return self;
}

-initWithMethodSignature:(NSMethodSignature*)signature
{
	return [self init];
}

+invocation
{
	return [[[self alloc] init] autorelease];
}

+invocationWithMethodSignature:(NSMethodSignature*)signature
{
	return [self  invocation];
}

extern id objc_msgSend( id target, SEL selector, ... );

-(void)recache
{
	cached=NULL;
	if ( useCaching && target && selector) {
//		cached=objc_msg_lookup( target, selector );
		cached=[target methodForSelector:selector];
	}
#if !LINUX	
	if (!cached) {
		cached=objc_msgSend;
	}
#endif
}

-(void)setTarget:newTarget
{
	[self _setTarget:newTarget];
	[self recache];
}

-(void)setUseCaching:(BOOL)shouldUseCaching
{
	[self _setUseCaching:shouldUseCaching];
	[self recache];
}

-(SEL)selector
{
	return selector;
}

-(void)setSelector:(SEL)newSelector
{
	selector=newSelector;
	[self recache];
}

-(void)setArgument:(void*)argbuf atIndex:(NSInteger)anIndex
{
	anIndex-=2;
	if ( anIndex >= 0 && anIndex < 6 ) {
		args[anIndex]=*(id*)argbuf;
	}
}

-(void)getReturnValue:(void*)returnValueBuf
{
	*(id*)returnValueBuf = result;
}

-resultOfInvoking
{
	return cached( target, selector, args[0], args[1],args[2],args[3] );
}

-resultOfInvokingWithArgs:(id*)newArgs count:(int)count
{
	int i;
	for (i=0;i<count;i++ ) {
		args[i]=newArgs[i];
	}
	return INVOKE( self );
}

-(void)invoke
{
	[self setResult:[self resultOfInvoking]];
}

-(void)dealloc
{
	[result release];
//	[target release];
	[super dealloc];
}

@end

@interface MPWConvenientInvocation : NSInvocation {}
-resultOfInvoking;
@end

@implementation MPWConvenientInvocation

-resultOfInvoking
{
	id result;
	[self invoke];
	[self getReturnValue:&result];
	return result;
}

@end

#ifndef RELEASE


@implementation MPWFastInvocation(testing)

+testInvocationOfClass:(Class)invocationClass
{
	SEL cat = @selector(stringByAppendingString:);
	NSMethodSignature *sig = [NSString instanceMethodSignatureForSelector:cat];
	NSInvocation *invocation=[invocationClass invocationWithMethodSignature:sig];
	id world=@" World!";
	[invocation setTarget:@"Hello"];
	[invocation setSelector:cat];
	[invocation setArgument:&world atIndex:2];
	return invocation;
}

+simpleSendWithInvocationOfClass:(Class)invocationClass
{
	SEL cat = @selector(class);
	NSMethodSignature *sig = [NSString instanceMethodSignatureForSelector:cat];
	NSInvocation *invocation=[invocationClass invocationWithMethodSignature:sig];
	[invocation setTarget:@"Hello"];
	[invocation setSelector:cat];
	return invocation;
}


+testBasicSend:(Class)invocationClass
{
	id invocationResult;
	id invocation = [self testInvocationOfClass:invocationClass];
	[invocation invoke];
	[invocation getReturnValue:&invocationResult];
	return invocationResult;
}

+(void)testBasicSendNSInvocation
{
	IDEXPECT( [self testBasicSend:[MPWConvenientInvocation class]], @"Hello World!", @"concating via NSInvocation");
}

+(void)testBasicSend
{
	IDEXPECT( [self testBasicSend:[MPWFastInvocation class]], @"Hello World!", @"concating via MPWFastInvocation");
}


#if FULL_MPWFOUNDATION && !WINDOWS && !LINUX

+(double)ratioOfNSInvocationToMPWFastInvocationSpeed:(BOOL)caching
{
	int i;
	MPWFastInvocation* fast=[self simpleSendWithInvocationOfClass:[MPWFastInvocation class]];
	id slow=[self simpleSendWithInvocationOfClass:[MPWConvenientInvocation class]];
	IMP invoke = [slow methodForSelector:@selector(resultOfInvoking)];
	MPWRusage* slowStart=[MPWRusage current];
#define SEND_COUNT 100000

	for (i=0;i<SEND_COUNT;i++) {
		invoke( slow, @selector(resultOfInvoking));
	}
	MPWRusage* slowTime=[MPWRusage timeRelativeTo:slowStart];
	[fast setUseCaching:caching];
	MPWRusage* fastStart=[MPWRusage current];
	for (i=0;i<SEND_COUNT;i++) {
		INVOKE(fast);
	}
	MPWRusage* fastTime=[MPWRusage timeRelativeTo:fastStart];
	double ratio = (double)[slowTime userMicroseconds] / (double)[fastTime userMicroseconds];
	NSLog(@"ratio of %@cached MPWFastInvocation compared to NSInvocation: %g",caching?@"":@"un",ratio);
	return ratio;
}

+(void)testFasterThanNSInvocationWithoutCaching
{
	double ratio = [self ratioOfNSInvocationToMPWFastInvocationSpeed:NO];
	NSAssert2( ratio > 5 ,@"ratio of non-cached fast invocation to normal invocation %g < %d  (this may fluctuate)",
				ratio,5);

}

+(void)testFasterThanNSInvocationWitCaching
{
	double ratio = [self ratioOfNSInvocationToMPWFastInvocationSpeed:YES];
	NSAssert2( ratio > 12 ,@"ratio of cached fast invocation to normal invocation %g < %d  (this may fluctuate)",
				ratio,12);   //  actual up to factor 18

}

+(void)testCachingFasterThanNonCaching
{
	double ratio1 = [self ratioOfNSInvocationToMPWFastInvocationSpeed:YES];
	double ratio2 = [self ratioOfNSInvocationToMPWFastInvocationSpeed:NO];
	NSAssert2( ratio1 > ratio2 ,@"cached ratio (%g) slower than noncaced %g",
				ratio1,ratio2);
}

#undef SEND_COUNT
#define SEND_COUNT 10000000

+(void)testCachedInvocationFasterThanMessaging
{
	MPWFastInvocation* fast=[self simpleSendWithInvocationOfClass:[MPWFastInvocation class]];
	int i;
	MPWRusage* slowStart=[MPWRusage current];

	for (i=0;i<SEND_COUNT;i++) {
		[@"Hello" class];
	}
	MPWRusage* slowTime=[MPWRusage timeRelativeTo:slowStart];
	[fast setUseCaching:YES];
	INVOKE(fast);
	MPWRusage* fastStart=[MPWRusage current];
	for (i=0;i<SEND_COUNT;i++) {
		INVOKE(fast);
	}
	MPWRusage* fastTime=[MPWRusage timeRelativeTo:fastStart];
	double ratio = (double)[slowTime userMicroseconds] / (double)[fastTime userMicroseconds];
	NSLog(@"cached invocation (%d) vs. plain message send (%d): %g x faster than normal message send",[fastTime userMicroseconds],[slowTime userMicroseconds],ratio);
	NSAssert2( ratio > 1.4 ,@"ratio of cached fast invocation to normal message send %g < %g",
				ratio,1.4);   
}

#endif

+(void)testIntArgAndReturnValue
{
	MPWFastInvocation *invocation = [self invocation];
	
	int three=3;
	NSInteger charAtThree;
	[invocation setSelector:@selector(characterAtIndex:)];
	[invocation setTarget:@"Hello World!"];
	[invocation setArgument:&three atIndex:2];
	charAtThree=(NSInteger)[invocation resultOfInvoking];
	INTEXPECT( charAtThree, 'l', @"character at three");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
				@"testBasicSendNSInvocation",
				@"testBasicSend",
#if FULL_MPWFOUNDATION
				@"testFasterThanNSInvocationWithoutCaching",
				@"testFasterThanNSInvocationWitCaching",
				@"testCachingFasterThanNonCaching",
				@"testCachedInvocationFasterThanMessaging",
#endif				
				@"testIntArgAndReturnValue",
				nil];
}

@end
#endif 