//
//  MPWDict2ObjStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWDict2ObjStream : MPWFlattenStream
{
    Class targetClass;
    SEL   objectCreationSelector;
    BOOL  needsToAlloc;
}

scalarAccessor_h(SEL, objectCreationSelector, setObjectCreationSelector )
scalarAccessor_h(Class, targetClass, setTargetClass )

-(instancetype)initWithClass:(Class)newTargetClass selector:(SEL)newTargetSelector target:(id)aTarget;
+(instancetype)streamWithClass:(Class)newTargetClass selector:(SEL)newTargetSelector target:(id)aTarget;

@end

