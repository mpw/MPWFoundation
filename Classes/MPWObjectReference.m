//
//  MPWObjectReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on Sun Jan 18 2004.
/*  
    Copyright (c) 2004-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import "MPWObjectReference.h"
#import "AccessorMacros.h"
#import "DebugMacros.h"

@implementation MPWObjectReference

idAccessor( targetObject, setTargetObject )

+objectReferenceWithTargetObject:newTarget
{
	return [[[self alloc] initWithTargetObject:newTarget] autorelease];
}

-initWithTargetObject:newTarget
{
	self=[super init];
	[self setTargetObject:newTarget];
	return self;
}

-(NSUInteger)hash
{
	return (NSUInteger)targetObject;
}

-copyWithZone:(NSZone*)zone
{
	return [self retain];
}

-referencedValue
{
	return targetObject;
}


-(BOOL)isEqual:otherObject
{
	return (otherObject == self) || ([otherObject hash] == (NSUInteger)targetObject);
}

-(void)dealloc
{
	[targetObject release];
	[super dealloc];
}

@end

@implementation NSObject(referecing)

-referenceToSelf
{
	return [MPWObjectReference objectReferenceWithTargetObject:self];
}

@end

@implementation MPWObjectReference(testing)


+(void)testBasicEquality
{
	id refedObject = @"Hello World";
	id ref1,ref2;
	ref1=[refedObject referenceToSelf];
	ref2=[refedObject referenceToSelf];
	IDEXPECT( ref1, ref2 , @"two separate references to same object should be equal ");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testBasicEquality",
		nil];
}


@end

