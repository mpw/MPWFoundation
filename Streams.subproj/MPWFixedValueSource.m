//
//  MPWFixedValueSource.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.05.21.
//

#import "MPWFixedValueSource.h"
#import "NSRunLoopAdditions.h"

@interface MPWFixedValueSource()

@property (nonatomic, strong) NSEnumerator *valuesEnumerator;
@property (nonatomic, strong) NSTimer *timer;


@end

@implementation MPWFixedValueSource

-(void)writeObject:(id)anObject
{
    id nextValue=self.valuesEnumerator.nextObject;
    if (!nextValue) {
        self.valuesEnumerator=self.values.objectEnumerator;
        nextValue=self.valuesEnumerator.nextObject;
    }
    [self.target writeObject:nextValue];
}

-(NSTimer*)createTimer
{
    return [NSTimer scheduledTimerWithTimeInterval:self.seconds target:self selector:@selector(writeObject:) userInfo:nil repeats:YES];
}

-(void)start
{
    if (!self.timer) {
        self.timer=[self createTimer];
    }
}

-(void)stop
{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)run
{
    [self start];
    [[NSRunLoop currentRunLoop] runInterruptibly];
    [self stop];
}

-(void)dealloc
{
    NSLog(@"deallocating MPWFixedValueSource, will stop timer");
    [self stop];
    [_values release];
    [_valuesEnumerator release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWFixedValueSource(testing) 

+(void)testWritesValuesRepeatedly
{
    MPWFixedValueSource *source=[MPWFixedValueSource stream];
    source.values=@[ @1, @7 ];
    IDEXPECT(source.target, @[], @"result empty");
    [source writeObject:nil];
    IDEXPECT(source.target, @[@1], @"one result");
    [source writeObject:nil];
    IDEXPECT(source.target, (@[@1, @7]), @"two results, at end");
    [source writeObject:nil];
    IDEXPECT(source.target, (@[@1, @7, @1]), @"three results, start from beginnig");
    [source writeObject:nil];
    IDEXPECT(source.target, (@[@1, @7, @1,@7]), @"four results, at end");
}

+(NSArray*)testSelectors
{
   return @[
			@"testWritesValuesRepeatedly",
			];
}

@end
