//
//  MPWKVCSoftPointer.m
//  MPWFoundation
//
//  Created by Marcel Weiher on Wed Oct 01 2003.
/*  
    Copyright (c) 2003-2017 by Marcel Weiher.  All rights reserved.
*/
//

#import "MPWKVCSoftPointer.h"
#import "DebugMacros.h"

@implementation MPWKVCSoftPointer

idAccessor( targetOrigin, setTargetOrigin )
idAccessor( kvcPath, setKvcPath )

-initWithTarget:initialTarget path:path
{
	self = [super init];
	[self setTargetOrigin:initialTarget];
	[self setKvcPath:path];
	return self;
}

-target
{
	return [[self targetOrigin] valueForKeyPath:[self kvcPath]];
}

-(void)dealloc
{
	[kvcPath release];
	[targetOrigin release];
	[super dealloc];
}

@end

@implementation MPWKVCSoftPointer(testing)



+(void)testFinalTarget
{
	id base = [NSDictionary dictionaryWithObjectsAndKeys:@"testValue",@"testKey",nil];
	MPWKVCSoftPointer* proxy = [[[self alloc] initWithTarget:base path:@"testKey"] autorelease];
	IDEXPECT( [proxy target], @"testValue" , @"target did not match" );
}

+(void)testPointerForObject
{
	id base = [NSDictionary dictionaryWithObjectsAndKeys:@"testValue",@"testKey",nil];
	MPWKVCSoftPointer* proxy = [base softPointerForKeyPath:@"testKey"];
	IDEXPECT( [proxy target], @"testValue" , @"target did not match" );
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testFinalTarget",
		@"testPointerForObject",
		nil];
}

@end

@implementation NSObject(kvcSoftPointer)

-softPointerForKeyPath:(NSString*)keyPath
{
	return [[[MPWKVCSoftPointer alloc] initWithTarget:self path:keyPath] autorelease];
}

@end

