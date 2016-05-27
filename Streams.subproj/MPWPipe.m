//
//  MPWPipe.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/05/16.
//
//

#import "MPWPipe.h"
#import "MPWMessageFilterStream.h"
#import "MPWBlockFilterStream.h"


@implementation MPWPipe

-(instancetype)initWithFilters:(NSArray *)filters
{
    self=[super initWithTarget:[NSMutableArray array]];
    self.filters=filters;
    [self connect];
    return self;
}

-(void)connect
{
    if ( self.filters.count > 1) {
        for (int i=0; i<self.filters.count-1;i++) {
            [self.filters[i] setTarget:self.filters[i+1]];
        }
    }
    [self.filters.lastObject setTarget:[self target]];
}

-(void)setTarget:(id <Streaming>)newTarget
{
    [super setTarget:newTarget];
    [self connect];
}

-(void)writeObject:(id)anObject
{
    [self.filters.firstObject writeObject:anObject];
}

-(void)setErrorTarget:newErrorTarget
{
    for ( id s in self.filters) {
        if ( [s respondsToSelector:@selector(setErrorTarget:)]) {
            [s setErrorTarget:newErrorTarget];
        }
    }
}

-(void)addFilter:(id <Streaming>)newFilter
{
    self.filters = [self.filters arrayByAddingObject:newFilter];
    [self connect];
}

@end


@implementation MPWPipe(testing)

+(void)testBasicPipe
{
    NSArray *filters =
    @[
      [MPWMessageFilterStream streamWithSelector:@selector(uppercaseString)],
      [MPWBlockFilterStream streamWithBlock:^(NSString *s){ return [s stringByAppendingString:@" World!"]; }],
      ];
    MPWPipe *pipe=[[self alloc] initWithFilters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([[pipe target] firstObject], @"HELLO World!", @"hello world, processed");
}

+(NSArray *)testSelectors
{
    return @[
             @"testBasicPipe",
             ];
}

@end