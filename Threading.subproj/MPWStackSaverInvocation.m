//
//  MPWStackSaverInvocation.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWStackSaverInvocation.h"
#import <AccessorMacros.h>

@implementation MPWStackSaverInvocation

objectAccessor(NSInvocation*, invocation, setInvocation )
objectAccessor(NSArray*, stackTrace, setStackTrace )

-initWithInvocation:(NSInvocation*)anInvocation
{
    self=[super init];
    [self setInvocation:anInvocation];
    [self setStackTrace:[NSThread callStackSymbols] ];
    return self;
}

+withInvocation:(NSInvocation*)anInvocation
{
    return [[[self alloc] initWithInvocation:anInvocation] autorelease];
}


-(void)invokeWithTarget:aTarget
{
    @try {
        [[self invocation] invokeWithTarget:aTarget];
    }
    @catch (NSException *exception) {
        NSLog(@"sending %@ to %@ raised %@, originating call stack: %@ userin",NSStringFromSelector([[self invocation] selector]),aTarget,exception,[self stackTrace]);
        @throw ;
    }
}

@end
