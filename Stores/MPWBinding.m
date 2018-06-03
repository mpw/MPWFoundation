//
//  MPWBinding.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWBinding.h"
#import "MPWAbstractStore.h"
#import "MPWGenericReference.h"
#import "AccessorMacros.h"

@implementation MPWBinding


CONVENIENCEANDINIT( binding, WithReference:(MPWGenericReference*)ref inStore:(MPWAbstractStore*)aStore)
{
    self=[super init];
    self.reference=ref;
    self.store=aStore;
    return self;
}

-value
{
    return [self.store objectForReference:self.reference];
}

-(void)setValue:newValue
{
    [self.store setObject:newValue forReference:self.reference];
}


-(void)delete
{
    [self.store deleteObjectForReference:self.reference];
}

-(BOOL)hasChildren
{
    return ![self.store isLeafReference:self.reference];
}

-(NSArray*)children
{
    return [self.store childrenOfReference:self.reference];
}

-(NSURL*)URL
{
    return [self.store URLForReference:self.reference];
}

-(NSString*)path
{
    return [self.reference path];
}

-(instancetype)div:(MPWBinding*)other
{
    return [[self class] bindingWithReference:[(MPWGenericReference*)[self reference] referenceByAppendingReference:(MPWGenericReference*)other.reference] inStore:self.store];
}

@end
