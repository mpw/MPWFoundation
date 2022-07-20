//
//  NSArrayFiltering.m
//  MPWFoundation
//
//  Created by marcel on Sun Aug 26 2001.
/*  
    Copyright (c) 2001-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import "NSArrayFiltering.h"
#import "NSObjectFiltering.h"
#import <MPWFoundation/MPWIgnoreTrampoline.h>
#import <MPWFoundation/NSInvocationAdditions_lookup.h>
//#import "MPWDirectForwardingTrampoline.h"

#define NXConstantString NSConstantString

@implementation NSArray(filtering)

-each
{
    return [self objectEnumerator];
}
#define OBJECTS_PER_ITERATION 100

#define FAST_MSG_LOOKUPS 0
#ifndef WINDOWS 

-(void)do:(SEL)selector args:(id*)args argCount:(int)maxArgs
{
	NSString *msg = @"[NSArray doInvocation, argument count %d exceeds maximum (4)";
#if	FAST_MSG_LOOKUPS
    IMP actionMethod=objc_msgSend;
#endif
 //   Class class=nil;
    long j,count=[self count];
    id objs[ OBJECTS_PER_ITERATION ];
    NSAssert1( maxArgs < 4 , msg ,maxArgs);  (void)msg;

    for (j=0;j<count;j+=OBJECTS_PER_ITERATION) {
        long max = (count-j)>OBJECTS_PER_ITERATION ? OBJECTS_PER_ITERATION : (count-j);
        int i;
        NSRange range={ j, max };
        [self getObjects:objs range:range];
        for (i=0;i<max;i++ ) {
			id obj=objs[i];
#if FAST_MSG_LOOKUPS
			CACHED_LOOKUP_WITH_CACHE( obj, selector, actionMethod, class );
            actionMethod( obj , selector,args[0],args[1],args[2],args[3] );            
#else
			[obj performSelector:selector withObject:args[0] withObject:args[1] ];
#endif
        }
    }
	
}

-collectFast:(NSInvocation*)invocation  // :(SEL)selector args:(id*)args argCount:(int)maxArgs
{
//	NSString *msg = @"[NSArray doInvocation, argument count %d exceeds maximum (4)";
#if	FAST_MSG_LOOKUPS
    IMP actionMethod=objc_msgSend;
#endif
	SEL selector = [invocation selector];
//    Class class=nil;
    long j,count=[self count];
	id args[4]={nil,nil,nil,nil};
    id objs[ OBJECTS_PER_ITERATION ];
	NSMutableArray *result=[NSMutableArray arrayWithCapacity:[self count]+20];
//	IMP addObject = [result methodForSelector:@selector(addObject:)];
//    NSAssert1( maxArgs < 4 , msg ,maxArgs);
    for (j=0;j<count;j+=OBJECTS_PER_ITERATION) {
        long max = (count-j)>OBJECTS_PER_ITERATION ? OBJECTS_PER_ITERATION : (count-j);
        int i;
        NSRange range={ j, max };
        [self getObjects:objs range:range];
        for (i=0;i<max;i++ ) {
			id obj=objs[i];
#if FAST_MSG_LOOKUPS
			CACHED_LOOKUP_WITH_CACHE( obj, selector, actionMethod, class );
            addObject( result, @selector(addObject:) , actionMethod( obj , selector,args[0],args[1],args[2],args[3] ));
#else
			[obj performSelector:selector withObject:args[0] withObject:args[1] ];
#endif
        }
    }
	return result;
}


-collectFastForSelector:(SEL)selector varargs:(va_list)varargs
{
//	NSString *msg = @"[NSArray doInvocation, argument count %d exceeds maximum (4)";
#if	FAST_MSG_LOOKUPS
    IMP actionMethod=objc_msgSend;
#endif
//    Class class=nil;
    long j,count=[self count];
	id args[4];
	for ( int i=0;i<4;i++) {
		args[i]=va_arg( varargs, id );
	}
    id objs[ OBJECTS_PER_ITERATION ];
	NSMutableArray *result=[NSMutableArray arrayWithCapacity:[self count]+20];
//	IMP addObject = [result methodForSelector:@selector(addObject:)];
	//    NSAssert1( maxArgs < 4 , msg ,maxArgs);
    for (j=0;j<count;j+=OBJECTS_PER_ITERATION) {
        long max = (count-j)>OBJECTS_PER_ITERATION ? OBJECTS_PER_ITERATION : (count-j);
        int i;
        NSRange range={ j, max };
        [self getObjects:objs range:range];
        for (i=0;i<max;i++ ) {
			id obj=objs[i];
#if FAST_MSG_LOOKUPS
			CACHED_LOOKUP_WITH_CACHE( obj, selector, actionMethod, class );
            addObject( result, @selector(addObject:) , actionMethod( obj , selector,args[0],args[1],args[2],args[3] ));
#else
			[obj performSelector:selector withObject:args[0] withObject:args[1] ];
#endif
        }
    }
	return result;
}					   
					   
#endif

				   
-(void)doInvocation:(NSInvocation*)invocation
{
	id args[4]={nil,nil,nil,nil};
	int j;
	long maxArgs = [[invocation methodSignature] numberOfArguments];
	maxArgs-=2;			//	0 is target, 1 is selector, 'real' args start at 2
	for ( j=0;j<maxArgs;j++ ) {
		[invocation getArgument:&args+j atIndex:j+2];
	}
	[self do:[invocation selector] args:args argCount:(int)maxArgs];
}


-emptyIgnoreTrampoline
{
    id trampoline = [MPWIgnoreTrampoline quickTrampoline];
    [trampoline setXxxTarget:[NSArray array]];
    return trampoline;
}

-collect
{
    if ( [self count] > 0 ) {
        return [super collect];
    } else {
        return [self emptyIgnoreTrampoline];
    }
}

-selectArg:(int)n
{
    if ( [self count] > 0 ) {
        return [super selectArg:n];
    } else {
        return [self emptyIgnoreTrampoline];
    }
}

-reject:(int)n
{
    if ( [self count] > 0 ) {
        return [super reject:n];
    } else {
        return [self emptyIgnoreTrampoline];
    }
}

#if 0
-doFastExperimental
{
    if ( [self count] > 0 ) {
		id trampoline = [MPWDirectForwardingTrampoline quickTrampoline];
		
		[trampoline setXxxTarget:self];
		[trampoline setXxxSelector:@selector(do:args:argCount:)];
		return trampoline;
    } else {
        return [self emptyIgnoreTrampoline];
    }
}
-collectFastExperimental
{
    if ( [self count] > 0 ) {
		id trampoline = [MPWDirectForwardingTrampoline quickTrampoline];
		
		[trampoline setXxxTarget:self];
		[trampoline setXxxSelector:@selector(collectFastForSelector:varargs:)];
		return trampoline;
    } else {
        return [self emptyIgnoreTrampoline];
    }
}
#endif
-asArray
{
    return [NSArray arrayWithArray:self];
}

-methodSignatureForHOMSelector:(SEL)selector
{
    NSLog(@"-[NSArray methodSignatureForHOMSelector:%@]",NSStringFromSelector(selector) );
    if ( [self count] > 0){
        return [[self objectAtIndex:0] methodSignatureForHOMSelector:selector];
    } else {
        return [self methodSignatureForSelector:@selector(asArray)];
    }
}

@end

@interface NSArrayFilteringTesting : NSObject

@end

#import "DebugMacros.h"

@implementation NSArrayFilteringTesting

+(void)testEmptyArrayCanCollectNoArgMessage
{
    NSArray *empty=[NSArray array];
    id trampoline=[empty collect];
    id result = [trampoline stringValue];
    INTEXPECT( [result count],0, @"length of result of collect-ing a zero-length source array with a zero arg message");
}

+testSelectors
{
    return @[
             @"testEmptyArrayCanCollectNoArgMessage",
             ];
}

@end


@implementation NSSet(filtering)

-emptyIgnoreTrampoline
{
    NSLog(@"emptyIgnore, will get trampoline");
    id trampoline = [MPWIgnoreTrampoline trampoline];
    NSLog(@"got trampoline: %p",trampoline);
    [trampoline setXxxTarget:[NSArray array]];
    NSLog(@"after set target, trampoline: %p",trampoline);
    return trampoline;
}


-collect
{
    if ( [self count] > 0 ) {
        return [super collect];
    } else {
        NSLog(@"return emptyIgnoreTrampile");
        return [self emptyIgnoreTrampoline];
    }
}



@end

@implementation NSArray(sorted)

typedef id (^SortBlock)(id a,id b);


static NSInteger compareUsingBlock( id a, id b, void *context )
{
    return [((SortBlock)context)(a,b) intValue];
}

-(NSArray*)sorted:(SortBlock)sortBlock
{
    return [self sortedArrayUsingFunction:compareUsingBlock context:sortBlock];
}

-sorted
{
    return [self sortedArrayUsingSelector:@selector(compare:)];
}


@end

