//
//  MPWScatterStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import "MPWScatterStream.h"



@implementation MPWScatterStream


-(NSArray *)filters
{
    return [super target];
}

-(void)setFilters:(NSArray *)newFilters
{
    return [super setTarget:newFilters];
}

-(id)target
{
    return [[self filters].firstObject target];
}

-(void)setTarget:(id)newTarget
{
    for ( id  scatterTarget in self.target) {
        if ( [scatterTarget respondsToSelector:@selector(setTarget:)] ) {
            [(MPWStream*)scatterTarget setTarget:newTarget];
        }
    }
}

+(instancetype)filters:(NSArray *)filters
{
    return [[[self alloc] initWithFilters:filters] autorelease];
}


-(instancetype)initWithFilters:(NSArray *)filters
{
    self = [super initWithTarget:nil];
    self.filters = filters;
    return self;
}

-(void)writeObject:(id)anObject
{
    NSLog(@"filters: %@",self.filters);
    for ( id <Streaming> scatterTarget in self.filters ) {
        NSLog(@"write: %@ to %@",anObject,scatterTarget);
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
