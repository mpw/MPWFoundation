//
//  MPWStackSaverInvocation.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWObject.h"
#import <Foundation/Foundation.h>

@interface MPWStackSaverInvocation : MPWObject
{
    NSInvocation *invocation;
    NSArray      *stackTrace;
}
+withInvocation:(NSInvocation*)anInvocation;
-(void)invokeWithTarget:aTarget;
@end
