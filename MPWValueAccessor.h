//
//  MPWValueAccessor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWObject.h"

typedef struct {
    Class       targetClass;
    int         targetOffset;
    SEL         getSelector,putSelector;
    IMP         getIMP,putIMP;
    id          additionalArg;
} AccessPathComponent;

@interface MPWValueAccessor : MPWObject
{
    id target;
    AccessPathComponent components[6];
    int count;
}

-initWithName:(NSString*)name;
-valueForTarget:aTarget;
-(void)setValue:newValue forTarget:aTarget;


@end
