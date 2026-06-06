//
//  MPWTypeToControlMapper.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.05.26.
//

#import "MPWTypeToControlMapper.h"
#import <Cocoa/Cocoa.h>



@implementation MPWTypeToControlMapper



-(instancetype)init
{
    self=[super init];
    self[@"bool"] = [MPWObjectTemplate templateWithClass:[NSButton class] values:@{ @"buttonType": @(NSButtonTypeSwitch),@"title": @"" }];
    self[@"id"] = [MPWObjectTemplate templateWithClass:[NSTextField class] values:@{ @"bezeled": @(false) }];
    return self;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTypeToControlMapper(testing) 

+(void)testMapTypes
{
    MPWTypeToControlMapper *mapper=[[self new] autorelease];
    MPWTypeStore *types=[MPWTypeStore store];
    EXPECTTRUE( [[mapper atType:types[@"id"]] isKindOfClass:[NSTextField class]], @"default text field");
    EXPECTTRUE( [[mapper atType:types[@"bool"]] isKindOfClass:[NSButton class]], @"bool to checkbox");
}

+(NSArray*)testSelectors
{
   return @[
			@"testMapTypes",
			];
}

@end
