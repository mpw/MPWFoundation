//
//  MPWValueAccessor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWObject.h"



@interface MPWValueAccessor : MPWObject
{
    @public
    IMP value;
}

+valueForName:(NSString*)name;
-initWithName:(NSString*)name;
-valueForTarget:aTarget;
-(void)setValue:newValue forTarget:aTarget;
-(NSString*)name;
-value;
-target;
-(void)bindToTarget:aTarget;

#define GETVALUE(accessor) (accessor->value( accessor, @selector(value)))


@end
