//
//  MPWTypeToControlMapper.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.05.26.
//

#import "MPWTypeToControlMapper.h"
#import <Cocoa/Cocoa.h>

@implementation MPWTypeToControlMapper



-(id)controlForType:(MPWTypeDefinition*)typeDefinition
{
    NSControl *control=nil;
    switch ( typeDefinition.objcTypeCode) {
        case 'B':
            control=[[[NSButton alloc] initWithDictionary:@{ @"buttonType": @(NSButtonTypeSwitch) }] autorelease];
            break;
        default:
            control = [[[NSTextField alloc] initWithDictionary:@{ @"bezeled": @(false) }] autorelease];
            break;
    }
    return control;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTypeToControlMapper(testing) 

+(void)testMapTypes
{
    MPWTypeToControlMapper *mapper=[[self new] autorelease];
    MPWTypeStore *types=[MPWTypeStore store];
    EXPECTTRUE( [[mapper controlForType:types[@"id"]] isKindOfClass:[NSTextField class]], @"default text field");
    EXPECTTRUE( [[mapper controlForType:types[@"bool"]] isKindOfClass:[NSButton class]], @"bool to checkbox");
}

+(NSArray*)testSelectors
{
   return @[
			@"testMapTypes",
			];
}

@end
