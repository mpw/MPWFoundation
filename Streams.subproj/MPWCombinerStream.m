//
//  MPWCombinerStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 16/09/2016.
//
//

#import "MPWCombinerStream.h"

@interface MPWCombinerStream ()

@property (nonatomic, strong) NSMutableDictionary *values;
@property (nonatomic, strong) NSArray *sourcePointers;


@end

@implementation MPWCombinerStream


-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.values=[NSMutableDictionary dictionary];
    return self;
}

-(void)setSources:(NSArray *)newSources
{
    NSMutableArray *sourcePointers=[NSMutableArray arrayWithCapacity:newSources.count];
    for ( id source in newSources ) {
        [sourcePointers addObject:[NSValue valueWithNonretainedObject:source]];
    }
    self.sourcePointers = sourcePointers;
}

-(void)writeObject:(id)anObject sender:aSender
{
    NSValue *senderPointer = [NSValue valueWithNonretainedObject:aSender];
    if ( [self.sourcePointers containsObject:senderPointer]) {
        self.values[senderPointer]=anObject;
    } else {
        NSLog(@"not in my set of sources");
    }
    if ( self.values.count ==  self.sourcePointers.count ) {
        [self.target writeObject:[self.values objectsForKeys:self.sourcePointers notFoundMarker:[NSNull null]] sender:self];
    }
}

-(void)dealloc
{
    [_sourcePointers release];
    [_values release];
    [super dealloc];
}

@end



@implementation MPWCombinerStream(testing)


+(void)testBasicCombinationSemantics
{
    NSMutableArray *testTarget=[NSMutableArray array];
    MPWCombinerStream *combiner=[self streamWithTarget:testTarget];
    MPWStream *source1=[MPWFlattenStream streamWithTarget:combiner];
    MPWStream *source2=[MPWFlattenStream streamWithTarget:combiner];
    [combiner setSources:@[ source1, source2]];
    INTEXPECT( testTarget.count, 0, @"haven't written anything yet");
    [source2 writeObject:@"test1 from source 2"];
    INTEXPECT( testTarget.count, 0, @"haven't written to both yet");
    [source2 writeObject:@"test2 from source 2"];
    INTEXPECT( testTarget.count, 0, @"still haven't written to both yet");
    [source1 writeObject:@"test1 from source 1"];
    INTEXPECT( testTarget.count, 1, @"now written to both");
    IDEXPECT( testTarget.firstObject, (@[ @"test1 from source 1",@"test2 from source 2" ]), @"combined contents");
    [source1 writeObject:@"test2 from source 1"];
    IDEXPECT( testTarget.lastObject, (@[ @"test2 from source 1",@"test2 from source 2" ]), @"combined contents");
    
}

+testSelectors
{
    return @[
             @"testBasicCombinationSemantics",
             ];
}

@end
