//
//  MPWConvertFromJSONStream.m
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import "MPWConvertFromJSONStream.h"

@implementation MPWConvertFromJSONStream

objectAccessor(NSString*, key, setKey)

CONVENIENCEANDINIT(stream, WithKey:(NSString*)newKey target:(id)aTarget)
{
    self=[super initWithTarget:aTarget];
    [self setKey:newKey];
    return self;
}

-(void)writeNSObject:(id)data
{
    NSError *jsonError=nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
    
    if ( !jsonError) {
        if (key ) {
            dict=dict[key];
        }
        FORWARD(dict)
    } else {
        [self reportError:jsonError];
    }
}

-(void)dealloc
{
    [key release];
    [super dealloc];
}


@end
