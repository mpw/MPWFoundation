//
//  MPWNumber.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20/3/07.
//  Copyright 2010-2017 by Marcel Weiher. All rights reserved.
//

#import "MPWNumber.h"


@implementation MPWNumber

-(NSString*)description
{
    return [self stringValue];
}

-(BOOL)isEqualToFloat:(float)floatValue
{
    return NO;
}

-(BOOL)isEqualToInteger:(int)intValue
{
    return NO;
}


@end
