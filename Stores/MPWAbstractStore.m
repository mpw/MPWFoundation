//
//  MPWAbstractStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWAbstractStore.h"
#import "MPWReference.h"


@implementation MPWAbstractStore

-objectForReference:(MPWReference*)aReference
{
    return nil;
}

-(void)setObject:theObject forReference:(MPWReference*)aReference
{
    return ;
}

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    return ;
}

-(NSArray*)childrenForReference:(MPWReference*)aReference
{
    return nil;
}

-(BOOL)hasChildren:(MPWReference*)aReference
{
    return NO;
}

-(MPWReference*)referenceForName:(NSString*)name inContext:aContext
{
    return nil;
}

-(MPWReference*)referenceForName:(NSString*)name
{
    return [self referenceForName:name inContext:nil];
}

@end

#import "DebugMacros.h"

@implementation MPWAbstractStore(testing)

+(void)testGenericsWork
{
    MPWAbstractStore<NSString*,NSArray*> *store=[MPWAbstractStore new];
    [store setObject:@[] forReference:@""];
    NSArray *a=[store objectForReference:@""];
    EXPECTNOTNIL( store, @"should have a store");
    EXPECTNIL( a, @"should not have a result");
}

+(NSArray*)testSelectors {  return @[
                                     @"testGenericsWork",
                                     ]; }

@end
