//
//  NSWindowAdditions.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 07.08.22.
//

#import "NSWindowAdditions.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation NSWindow(additions)

-(instancetype)initWithDictionary:(NSDictionary*)dict
{
    NSSet *excluded=[NSSet setWithArray:@[ @"frame", @"views"]];
    NSRect r=[(MPWRect*)dict[@"frame"] rectValue];
    self = [self initWithContentRect:r styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO];
    for (NSString *key in [dict allKeys]) {
        if (![excluded containsObject:key]) {
            [self setValue:dict[key] forKey:key];
        }
    }
    for (id subview in dict[@"views"]) {
        [self addSubview:subview];
    }
    return self;
}

-(void)addSubview:(NSView*)subview
{
    [[self contentView] addSubview:subview];
}


@end
