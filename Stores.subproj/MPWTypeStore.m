//
//  MPWTypeStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.26.
//

#import "MPWTypeStore.h"
#import "MPWTypeDefinition.h"

@implementation MPWTypeStore

-at:identifier
{
    return [MPWTypeDefinition descriptorForTypeName:[identifier stringValue]];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTypeStore(testing) 

+(void)testKnowsAboutID
{
    MPWTypeStore *types = [self store];
    MPWTypeDefinition *idDescriptor=types[@"id"];
    
    IDEXPECT( idDescriptor.name, @"id", @"stName");
    IDEXPECT( idDescriptor.cName, @"id", @"cName");
    INTEXPECT( idDescriptor.objcTypeCode, '@', @"type code");
    
    
}

+(void)testKnowsAboutSEL
{
    MPWTypeStore *types = [self store];
    MPWTypeDefinition *idDescriptor=types[@"SEL"];
    
    IDEXPECT( idDescriptor.name, @"SEL", @"stName");
    IDEXPECT( idDescriptor.cName, @"SEL", @"cName");
    INTEXPECT( idDescriptor.objcTypeCode, ':', @"type code");
    
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testKnowsAboutID",
       @"testKnowsAboutSEL",
			];
}

@end
