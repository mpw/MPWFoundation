//
//  MPWValueAccessor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWObject.h"

@interface MPWValueAccessor : MPWObject
{
    SEL getSelector,putSelector;
    id target;
    IMP putIMP,getIMP;
}

-initWithName:(NSString*)name;
-valueForTarget:aTarget;
-(void)setValue:newValue forTarget:aTarget;


@end
