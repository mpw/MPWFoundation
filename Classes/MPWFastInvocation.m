//
//  MPWFastInvocation.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 27/3/07.
//  Copyright 2010-2017 by Marcel Weiher. All rights reserved.
//

#import "MPWFastInvocation.h"
#import "DebugMacros.h"
#import <AccessorMacros.h>
#import "NSInvocationAdditions_lookup.h"
#define FULL_MPWFOUNDATION 1
#if FULL_MPWFOUNDATION && !WINDOWS && !LINUX
#import "MPWRusage.h"
#endif
#import "MPWObjectCache.h"


@implementation MPWFastInvocation

CACHING_ALLOC( quickInvocation, 5, YES )

scalarAccessor( id, target, _setTarget )
idAccessor( result, setResult )
boolAccessor( useCaching, _setUseCaching )
lazyAccessor( NSMethodSignature*, methodSignature, setMethodSignature, getSignature)
// extern id objc_msgSend( id receiver, SEL _cmd, ... );

-(NSMethodSignature*)getSignature
{
    return [target methodSignatureForSelector:selector ];
}


-copyWithZone:aZone
{
    return [self retain];
}

-init
{
	self = [super init];
    if ( self && !invokeFun) {
        invokeFun=(IMP0)[self methodForSelector:@selector(resultOfInvoking)];
    }
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

//extern id objc_msgSend( id target, SEL selector, ... );

-(void)recache
{
	cached=NULL;
	if ( useCaching && target && selector) {
//		cached=objc_msg_lookup( target, selector );
		cached=(IMP0)[target methodForSelector:selector];
	}
#if !LINUX	
	if (!cached) {
		cached=(IMP0)objc_msgSend;
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

-(void)setReturnValue:(void*)retval
{
	[self setResult:*(id*)retval];
}

//typedef id (*IMP4)(id, SEL, id,id,id,id);


-resultOfInvoking
{
	return ((IMP4)cached)( target, selector, args[0], args[1],args[2],args[3] );
}

-(id)invokeWithArgs:(va_list)varArgs
{
    for (int i=0;i<3;i++) {
        args[i]=va_arg(varArgs, id);
    }
    va_end(varArgs);
    return [self resultOfInvoking];
}

-(void)invokeWithTarget:aTarget
{
    [self setTarget:aTarget];
    [self resultOfInvoking];
}

-returnValueAfterInvokingWithTarget:aTarget
{
    id retval = ((IMP4)cached)( aTarget, selector, args[0], args[1],args[2],args[3] );
    return retval;
}

-resultOfInvokingWithArgs:(id*)newArgs count:(int)count
{
    return ((IMP4)cached)( target, selector, newArgs[0], newArgs[1],newArgs[2],newArgs[3] );
}

-(void)invoke
{
	[self setResult:[self resultOfInvoking]];
}

-(void)retainArguments
{
//    NSLog(@"MPWFastInvocation retainArguments");
}

-(NSString *)description
{
    //--- target may be deallocated so don't %@ it...
    return [NSString stringWithFormat:@"<%@:%p:[%p  %@]>",[self class],self,target,NSStringFromSelector(selector)];
}

-(void)dealloc
{
//    NSLog(@"dealloc MPWFastInvocation %p",self);
    [methodSignature release];
	[result release];
	[super dealloc];
}

@end

@implementation NSInvocation(convenience)

-resultOfInvoking
{
	id result;
	[self invoke];
	[self getReturnValue:&result];
	return result;
}

@end



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
	IDEXPECT( [self testBasicSend:[NSInvocation class]], @"Hello World!", @"concating via NSInvocation");
}

+(void)testBasicSend
{
	IDEXPECT( [self testBasicSend:[MPWFastInvocation class]], @"Hello World!", @"concating via MPWFastInvocation");
}


//#if FULL_MPWFOUNDATION && !WINDOWS && !LINUX

+(double)ratioOfNSInvocationToMPWFastInvocationSpeed:(BOOL)caching
{
	int i;
	MPWFastInvocation* fast=[self simpleSendWithInvocationOfClass:[MPWFastInvocation class]];
	id slow=[self simpleSendWithInvocationOfClass:[NSInvocation class]];
	IMP0 invoke = (IMP0)[slow methodForSelector:@selector(resultOfInvoking)];
	MPWRusage* slowStart=[MPWRusage current];
#define SEND_COUNT 10000

	for (i=0;i<SEND_COUNT;i++) {
		invoke( slow, @selector(resultOfInvoking));
	}
	MPWRusage* slowTime=[MPWRusage timeRelativeTo:slowStart];
//    NSLog(@"slowTime: %@",slowTime);
//    NSLog(@"slowTime: %g",(double)[slowTime userMicroseconds]);
	[fast setUseCaching:caching];
	MPWRusage* fastStart=[MPWRusage current];
	for (i=0;i<SEND_COUNT;i++) {
		INVOKE(fast);
	}
	MPWRusage* fastTime=[MPWRusage timeRelativeTo:fastStart];
//    NSLog(@"fastTime: %@",fastTime);
//    NSLog(@"fastTime: %g",(double)[fastTime userMicroseconds]);
	double ratio = (double)[slowTime cpu] / (double)[fastTime cpu];
	NSLog(@"ratio of %@cached MPWFastInvocation compared to NSInvocation: %g",caching?@"":@"un",ratio);
	return ratio;
}

+(void)testFasterThanNSInvocationWithoutCaching
{
	double ratio = [self ratioOfNSInvocationToMPWFastInvocationSpeed:NO];
	NSAssert2( ratio > 5 ,@"ratio of non-cached fast invocation to normal invocation %g < %d  (this may fluctuate)",
				ratio,5);
    (void)ratio;

}

+(void)testFasterThanNSInvocationWitCaching
{
	double ratio = [self ratioOfNSInvocationToMPWFastInvocationSpeed:YES];
	NSAssert2( ratio > 12 ,@"ratio of cached fast invocation to normal invocation %g < %d  (this may fluctuate)",
				ratio,12);   //  actual up to factor 18

    (void)ratio;
}

+(void)testCachingFasterThanNonCaching
{
	double ratio1 = [self ratioOfNSInvocationToMPWFastInvocationSpeed:YES];
	double ratio2 = [self ratioOfNSInvocationToMPWFastInvocationSpeed:NO];
	NSAssert2( ratio1 > ratio2 ,@"cached ratio (%g) slower than noncaced %g",
				ratio1,ratio2);
    (void)ratio1;
    (void)ratio2;

}

#undef SEND_COUNT
#define SEND_COUNT 10000

+(void)testCachedInvocationFasterThanMessaging
{
	MPWFastInvocation* fast=[self simpleSendWithInvocationOfClass:[MPWFastInvocation class]];
	int i;
	MPWRusage* slowStart=[MPWRusage current];

	for (i=0;i<SEND_COUNT;i++) {
		[@"Hello" length];
	}
	MPWRusage* slowTime=[MPWRusage timeRelativeTo:slowStart];
	[fast setUseCaching:YES];
	INVOKE(fast);
	MPWRusage* fastStart=[MPWRusage current];
	for (i=0;i<SEND_COUNT;i++) {
		INVOKE(fast);
	}
	MPWRusage* fastTime=[MPWRusage timeRelativeTo:fastStart];
	double ratio = (double)[slowTime cpu] / (double)[fastTime cpu];
//	NSLog(@"cached invocation (%d) vs. plain message send (%d): %g x speed of normal message send",(int)[fastTime cpu],(int)[slowTime cpu],ratio);
	NSAssert2( ratio > 0.2 ,@"ratio of cached fast invocation to normal message send %g < %g",
				ratio,0.2);
}

//#endif

+(void)testIntArgAndReturnValue
{
	MPWFastInvocation *invocation = [self invocation];
	
	long positionArg=3;
	[invocation setSelector:@selector(characterAtIndex:)];
	[invocation setTarget:@"Hello World!"];
	[invocation setArgument:&positionArg atIndex:2];
//	charAtThree=(NSInteger)[invocation resultOfInvoking];
    INTEXPECT( (NSInteger)[invocation resultOfInvoking], 'l', @"character at three");
    positionArg=4;
    [invocation setArgument:&positionArg atIndex:2];
    INTEXPECT( (NSInteger)[invocation resultOfInvoking], 'o', @"character at four");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
				@"testBasicSendNSInvocation",
				@"testBasicSend",
				@"testFasterThanNSInvocationWithoutCaching",
				@"testFasterThanNSInvocationWitCaching",
//				@"testCachingFasterThanNonCaching",
				@"testCachedInvocationFasterThanMessaging",
				@"testIntArgAndReturnValue",
				nil];
}

@end

