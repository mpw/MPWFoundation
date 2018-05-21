//
//  MPWAbstractStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWAbstractStore.h"

@implementation MPWAbstractStore

-objectForReference:aReference
{
    return nil;
}

-(void)setObject:theObject forReference:aReference
{
    return ;
}

-(void)deleteObjectForReference:aReference
{
    return ;
}

-(NSArray*)childrenForReference:aReference
{
    return nil;
}

-(BOOL)hasChildren:aReference
{
    return NO;
}

-referenceForName:(NSString*)name
{
    return nil;
}

@end


@implementation MPWAbstractStore(testing)

+(void)testSomething
{
    MPWAbstractStore<NSString,NSObject> *store=[MPWAbstractStore new];
    
}

+(NSArray*)testSelectors {  return @[]; }

@end
