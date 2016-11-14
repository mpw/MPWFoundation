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


-(void)insertNewObject:(id)anObject forSender:aSender
{
    @synchronized (self) {
        NSValue *senderPointer = [NSValue valueWithNonretainedObject:aSender];
        if ( [self.sourcePointers containsObject:senderPointer]) {
            self.values[senderPointer]=anObject;
        }
    }
}

-(NSArray *)combinedResult
{
    NSArray *combined=nil;
    @synchronized (self) {
        if ( self.values.count ==  self.sourcePointers.count ) {
            NSMutableArray *tempCombined=[NSMutableArray arrayWithCapacity:self.values.count];
            for ( id key in self.sourcePointers ) {
                id value=self.values[key];
                if (value) {
                    [tempCombined addObject:value];
                }
            }
            combined=[[tempCombined copy] autorelease];
        }
    }
    return combined;
}

-(void)writeObject:(id)anObject sender:aSender
{
    [self insertNewObject:anObject forSender:aSender];
    [self.target writeObject:[self combinedResult] sender:self];
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
    MPWCombinerStream *combiner=[self stream];
    NSMutableArray *testTarget=combiner.target;
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


+(void)testIncompleteAllowed
{
    MPWCombinerStream *combiner=[self stream];
    NSMutableArray *testTarget=combiner.target;
}

+testSelectors
{
    return @[
             @"testBasicCombinationSemantics",
             ];
}

@end
