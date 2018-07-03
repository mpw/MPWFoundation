//
//  MPWStreamCompositionTests.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14/11/2016.
//
//

#import "MPWStreamCompositionTests.h"
#import "MPWFoundation.h"
#import "MPWCombinerStream.h"

@implementation MPWStreamCompositionTests


+(MPWStream *)combiner
{
    MPWCombinerStream *combiner=[MPWCombinerStream stream];
    MPWStream *source1=[MPWFlattenStream streamWithTarget:combiner];
//    MPWStream *source2=[MPWFlattenStream streamWithTarget:combiner];
    [combiner setSources:@[ source1 ]];

    return source1;
}

+(void)testCombinerWithPipeline
{
    NSArray *target=[NSMutableArray array];
    MPWStream *combiner=[self combiner];
    MPWPipeline *pipe=[MPWPipeline filters:@[ [MPWFlattenStream stream] ]];
    [combiner.target setTarget:pipe];
    pipe.target=target;
    [combiner writeObject:@"hello"];
    IDEXPECT(target.firstObject, @"hello", @"should have written");
}

+(void)testCombinerWithBlockFilter
{
    NSArray *target=[NSMutableArray array];
    MPWStream *combiner=[self combiner];
    MPWBlockFilterStream *pipe=[MPWBlockFilterStream streamWithBlock:^(NSArray *array){
        return [array.firstObject uppercaseString];
    }];
    [combiner.target setTarget:pipe];
    pipe.target=target;
    [combiner writeObject:@"hello"];
    IDEXPECT(target.firstObject, @"HELLO", @"should have written");
}

+testSelectors
{
    return @[
             @"testCombinerWithBlockFilter",
             @"testCombinerWithPipeline",

             ];
}


@end
