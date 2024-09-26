//
//  MPWValueReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26.09.24.
//

#import "MPWValueReference.h"

@implementation MPWValueReference
{
    id value;
}

objectAccessor(id, value, setValue)

-(instancetype)initWithValue:newValue
{
    self=[super init];
    [self setValue:newValue];
    return self;
}

+(instancetype)value:newValue
{
    return [[[self alloc] initWithValue:newValue] autorelease];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWValueReference(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
