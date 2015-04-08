//
//  MPWDict2ObjStream.m
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import "MPWDict2ObjStream.h"

@implementation MPWDict2ObjStream

scalarAccessor(SEL, objectCreationSelector, setObjectCreationSelector )
scalarAccessor(Class, targetClass, setTargetClass )
boolAccessor( needsToAlloc, setNeedsToAlloc )

CONVENIENCEANDINIT(stream, WithClass:(Class)newTargetClass selector:(SEL)newTargetSelector target:(id)aTarget )
{
    self=[super initWithTarget:aTarget];
    [self setTargetClass:newTargetClass];
    if ( !newTargetSelector) {
        newTargetSelector=@selector(initWithDictionary:);
    }
    [self setNeedsToAlloc:[newTargetClass instancesRespondToSelector:newTargetSelector]];
    [self setObjectCreationSelector:newTargetSelector];
    return self;
}

-(id)initWithTarget:(id)aTarget
{
    [self release];
    [NSException raise:@"parameterassert" format:@"Dict2ObjStream must be created with target class and selector"];
    return nil;
}

-(void)writeDictionary:(NSDictionary *)anObject
{
    id targetObject=targetClass;
    if ( targetObject && objectCreationSelector) {
        targetObject=targetClass;
        if ( needsToAlloc){
            targetObject=[targetObject alloc];
        }
        anObject=[targetObject performSelector:objectCreationSelector withObject:anObject];
    }
    [target writeObject:anObject];
}


@end
