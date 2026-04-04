//
//  MPWVariableDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWVariableDefinition.h"

@implementation MPWVariableDefinition


-initWithName:(NSString*)newName type:(MPWTypeDefinition*)newType
{
    self=[super init];
    self.name = newName;
    self.type = newType;
    return self;
}

-(void)dealloc
{
    [_name release];
    [_type release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWVariableDefinition(testing) 

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
