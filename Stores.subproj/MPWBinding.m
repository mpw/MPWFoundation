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
#import "MPWPathRelativeStore.h"

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
    return [(MPWGenericReference*)self.reference path];
}

-(instancetype)div:(MPWBinding*)other
{
    return [[self class] bindingWithReference:[(MPWGenericReference*)[self reference] referenceByAppendingReference:(MPWGenericReference*)other.reference] inStore:self.store];
}

-asScheme
{
    return [MPWPathRelativeStore storeWithSource:self.store reference:self.reference];
}

-(NSArray*)pathComponents
{
    return self.reference.pathComponents;
}

-(NSArray*)relativePathComponents
{
    return self.reference.pathComponents;
}

-(NSString*)schemeName
{
    return self.reference.schemeName;
}

-(void)setSchemeName:(NSString*)newName
{
    self.reference.schemeName=newName;
}

- (instancetype)referenceByAppendingReference:(id<MPWReferencing>)other {
    return [[self class] bindingWithReference:[(MPWGenericReference*)[self reference] referenceByAppendingReference:(MPWGenericReference*)other] inStore:self.store];
}

-(void)traverse:(id <Streaming>)target
{
    [target writeObject:self];
    if ( [self hasChildren]) {
        [[[self children] do] traverse:target];
    }
}

-(void)dealloc
{
    [(id)_reference release];
    [_store release];
    [super dealloc];
}


@end
