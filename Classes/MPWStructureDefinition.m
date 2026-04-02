//
//  MPWStructureDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWStructureDefinition.h"
#import "AccessorMacros.h"

@implementation MPWStructureDefinition

CONVENIENCEANDINIT( structure, WithFields:newFields )
{
    self=[super init];
    self.fields = newFields;
    return self;
}

-(void)dealloc
{
    [_fields release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStructureDefinition(testing) 

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
