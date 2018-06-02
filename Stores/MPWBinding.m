//
//  MPWResolvedReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWBinding.h"
#import "MPWAbstractStore.h"
#import "MPWReference.h"

@implementation MPWBinding

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

-(NSURL*)URL
{
    return [self.store URLForReference:self.reference];
}


@end
