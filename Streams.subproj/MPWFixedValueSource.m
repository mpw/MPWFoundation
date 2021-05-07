//
//  MPWFixedValueSource.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.05.21.
//

#import "MPWFixedValueSource.h"

@interface MPWFixedValueSource()

@property (nonatomic, strong) NSEnumerator *valuesEnumerator;


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

-(NSTimer*)timer
{
    return [NSTimer scheduledTimerWithTimeInterval:self.seconds target:self selector:@selector(writeObject:) userInfo:nil repeats:YES];
}

-(void)run
{
    [self timer];
    [[NSRunLoop currentRunLoop] run];
}

-(void)dealloc
{
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
