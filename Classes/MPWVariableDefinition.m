//
//  MPWVariableDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWVariableDefinition.h"
#import "MPWTypeDefinition.h"

@implementation MPWVariableDefinition


-initWithName:(NSString*)newName type:(MPWTypeDefinition*)newType
{
    self=[super init];
    self.name = newName;
    self.type = newType;
    self.operations = MPWRESTVerbsReadWrite;
    return self;
}

+(instancetype)idWithName:(NSString*)newName
{
    return [[[self alloc] initWithName:newName type:[MPWTypeDefinition idType]] autorelease];
}

+(instancetype)int64WithName:(NSString*)newName
{
    return [[[self alloc] initWithName:newName type:[MPWTypeDefinition int64Type]] autorelease];
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
