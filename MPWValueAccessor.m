//
//  MPWValueAccessor.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWValueAccessor.h"
#import "AccessorMacros.h"
#import <Foundation/Foundation.h>

@implementation MPWValueAccessor

idAccessor(target, _setTarget)

extern id objc_msgSend(id, SEL, ...);
-initWithName:(NSString*)name
{
    self=[super init];
    if ( self ) {
        getSelector= NSSelectorFromString(name);
        putSelector=NSSelectorFromString([@"set" stringByAppendingString:[name capitalizedString]]);
        getIMP=objc_msgSend;
        putIMP=objc_msgSend;
        
    }
    return self;
}

-valueForTarget:aTarget
{
    return getIMP( aTarget, getSelector );
}

-(void)setValue:newValue forTarget:aTarget
{
    putIMP( aTarget, putSelector, newValue );
}

-(void)bindToTarget:aTarget
{
    [self _setTarget:aTarget];
    getIMP=[aTarget methodForSelector:getSelector];
    putIMP=[aTarget methodForSelector:putSelector];
    if ( (getIMP == NULL) || (putIMP == NULL) ) {
        [NSException raise:@"bind failed" format:@"bind failed"];
    }
}

-value {  return getIMP( target, getSelector ); }

-(void)setValue:newValue
{
    putIMP( target , putSelector, newValue );
}


@end


