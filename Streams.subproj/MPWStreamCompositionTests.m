//
//  MPWStreamCompositionTests.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14/11/2016.
//
//

#import "MPWStreamCompositionTests.h"
#import "MPWCombinerStream.h"
#import "MPWMapFilter.h"
#import "MPWFlattenStream.h"
#import "MPWPipeline.h"
#import "DebugMacros.h"


@implementation MPWStreamCompositionTests


+(MPWFilter *)combiner
{
    MPWCombinerStream *combiner=[MPWCombinerStream stream];
    MPWFlattenStream *source1=[MPWFlattenStream streamWithTarget:combiner];
//    MPWWriteStream *source2=[MPWFlattenStream streamWithTarget:combiner];
    [combiner setSources:@[ source1 ]];

    return source1;
}

+(void)testCombinerWithPipeline
{
    NSArray *target=[NSMutableArray array];
    MPWFilter *combiner=[self combiner];
    MPWPipeline *pipe=[MPWPipeline filters:@[ [MPWFlattenStream stream] ]];
    [(MPWFilter*)combiner.target setTarget:pipe];
    pipe.target=(MPWWriteStream*)target; // FIXME?
    [combiner writeObject:@"hello"];
    IDEXPECT(target.firstObject, @"hello", @"should have written");
}

+(void)testCombinerWithBlockFilter
{
    NSArray *target=[NSMutableArray array];
    MPWFilter *combiner=[self combiner];
    MPWMapFilter *pipe=[MPWMapFilter filterWithBlock:^(NSArray *array){
        return [array.firstObject uppercaseString];
    }];
    [(MPWFilter*)combiner.target setTarget:pipe];
    pipe.target=(MPWWriteStream*)target; // FIXME?
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
