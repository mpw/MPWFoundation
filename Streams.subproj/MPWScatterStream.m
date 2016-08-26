//
//  MPWScatterStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import "MPWScatterStream.h"



@implementation MPWScatterStream

+(instancetype)filters:(NSArray *)filters
{
    return [[[self alloc] initWithFilters:filters] autorelease];
}


-(instancetype)initWithFilters:(NSArray *)filters
{
    return [self initWithTarget:filters];
}

-(void)writeObject:(id)anObject
{
    for ( id <Streaming> scatterTarget in self.target) {
        [scatterTarget writeObject:anObject];
    }
}


@end


#import "DebugMacros.h"

@implementation MPWScatterStream(testing)

+(void)testSendsToMultiple
{
    NSMutableArray *receiver1=[NSMutableArray array];
    NSMutableArray *receiver2=[NSMutableArray array];
    NSMutableArray *receiver3=[NSMutableArray array];
    
    MPWStream *scatterer=[self filters:@[ receiver1, receiver2, receiver3 ] ];
    [scatterer writeObject:@"test object"];
    IDEXPECT(receiver1.firstObject, @"test object", @"first target");
    IDEXPECT(receiver2.firstObject, @"test object", @"second target");
    IDEXPECT(receiver3.firstObject, @"test object", @"third target");
}

+(NSArray *)testSelectors
{
    return @[
             @"testSendsToMultiple",
             ];
}

@end
