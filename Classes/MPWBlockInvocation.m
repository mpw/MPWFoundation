//
//  MPWBlockInvocation.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/8/11.
//  Copyright 2012 by Marcel Weiher. All rights reserved.
//

#import "MPWBlockInvocation.h"
#import <AccessorMacros.h>

//#if NS_BLOCKS_AVAILABLE


@implementation MPWBlockInvocation

idAccessor( block, _setBlock )

-(void)setBlock:aBlock
{
	[self _setBlock:[[aBlock copy] autorelease]];
}

-(instancetype)initWithBlock:aBlock
{
	self=[super init];
	[self setBlock:aBlock];
	return self;
}

+invocationWithBlock:aBlock 
{
	return [[(MPWBlockInvocation*)[self alloc] initWithBlock:aBlock] autorelease];
}

-resultOfInvokingWithArgs:(id*)newArgs count:(int)count
{
	switch ( count ) {
		case 0:
			return ((id (^)(void))block)();
		case 1:
			return ((id (^)(id))block)(newArgs[0]);
		case 2:
			return ((id (^)(id,id))block)(newArgs[0],newArgs[1]);
		case 3:
			return ((id (^)(id,id,id))block)(newArgs[0],newArgs[1],newArgs[2]);
		case 4:
			return ((id (^)(id,id,id,id))block)(newArgs[0],newArgs[1],newArgs[2],newArgs[3]);
		case 5:
			return ((id (^)(id,id,id,id,id))block)(newArgs[0],newArgs[1],newArgs[2],newArgs[3],newArgs[4]);
		case 6:
			return ((id (^)(id,id,id,id,id,id))block)(newArgs[0],newArgs[1],newArgs[2],newArgs[3],newArgs[4],newArgs[5]);
	 default:
			@throw( [NSString stringWithFormat:@"resultOfInvokingWithArgs unsupported number of args: %d",count] );
	}

}

@end

#import "DebugMacros.h"

@implementation MPWBlockInvocation(testing)

+(void)testInvokeZeroArgBlock
{
	MPWBlockInvocation *invocation = [MPWBlockInvocation invocationWithBlock:^{ return 42; } ];
	EXPECTNOTNIL( invocation, @"should have gotten a block");
	INTEXPECT( (long)[invocation resultOfInvokingWithArgs:NULL count:0] ,42, @"result of block");
	
}

+(void)testInvokeThreeArgBlock
{
	MPWBlockInvocation *invocation = [MPWBlockInvocation invocationWithBlock:^(NSInteger a,NSInteger b,NSInteger c){ return (a+b)*c; } ];
	EXPECTNOTNIL( invocation, @"should have gotten a block");
	NSInteger array[3]={ 3 , 4 , 5 };
	INTEXPECT( (long)[invocation resultOfInvokingWithArgs:(id*)array count:3] ,35, @"result of block");
	
}

+testSelectors {
	return [NSArray arrayWithObjects:
			@"testInvokeZeroArgBlock",
			@"testInvokeThreeArgBlock",
			nil];
}

@end


//#endif
