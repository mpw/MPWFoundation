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
    NSLog(@"initWithFilters");
    self=[super initWithTarget:[NSMutableArray array]];
    self.filters=filters;
    [self connect];
    NSLog(@"return from initWithFilters");
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