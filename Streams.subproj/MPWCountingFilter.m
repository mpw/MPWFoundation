//
//  MPWCountingFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 29.07.25.
//

#import "MPWCountingFilter.h"
#import "MPWFilter.h"

@interface MPWCountingFilter()

@property (nonatomic,assign) long autoFlush;

@end


@implementation MPWCountingFilter
{
    long count;
}

-(void)writeObject:(id)anObject sender:sourceStream
{
    count++;
    if ( count && self.autoFlush && ((count % self.autoFlush) == 0 )) {
        [self flushLocal];
    }
}

-(void)flushLocal
{
    FORWARD( @(count));
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWCountingFilter(testing) 

+(void)testBasicCounting
{
    MPWCountingFilter *counter=[self stream];
    [counter writeObject:@"10"];
    [counter writeObject:@"21"];
    [counter close];
    IDEXPECT( [counter.target firstObject], @(2), @"objects written");

}

+(NSArray*)testSelectors
{
   return @[
       @"testBasicCounting",
			];
}

@end
