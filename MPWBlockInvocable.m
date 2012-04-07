//
//  MPWBlockInvocable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWBlockInvocable.h"



@implementation MPWBlockInvocable

#if 0

static void *copy(void *dst, void *src) {  return 

/** Optional block dispose helper. May be NULL. */
static void *dispose(void *) 
#endif


static struct Block_descriptor sdescriptor= {
		0, 64, NULL, NULL
};

-(id)invokeWithArgs:(va_list)args
{
	return self;
}


static id blockFun( id self, ... ) {
	va_list args;
	va_start( args, self );
	id result=[self invokeWithArgs:args];
	va_end( args );
	return result;
}

-(IMP)invokeMapper
{
	return (IMP)blockFun;
}

-init
{
	self=[super init];
	if ( self ) {
		invoke=(IMP)[self invokeMapper];
		descriptor=&sdescriptor;
		flags=(1 << 28);
	}
	return self;
}


@end

#if NS_BLOCKS_AVAILABLE

#import "DebugMacros.h"

@interface MPWBlockInvocableTest : MPWBlockInvocable
{
}
@end


@implementation MPWBlockInvocableTest

typedef int (^intBlock)(int arg );


-(id)invokeWithArgs:(va_list)args
{
	return (id)(va_arg( args, int ) * 3);
}

+(void)testBlockInvoke
{
	id blockObj = [[[self alloc] init] autorelease];
	INTEXPECT( ((intBlock)blockObj)( 3 ), 9, @"block(3) ");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
					@"testBlockInvoke",
			nil];
}

@end

#endif
