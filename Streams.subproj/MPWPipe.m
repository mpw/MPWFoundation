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

@interface MPWPipe()

@property (nonatomic, strong) NSArray *filters;


@end


@implementation MPWPipe



-(instancetype)initWithFilters:(NSArray *)filters
{
    self=[super initWithTarget:[NSMutableArray array]];
    self.filters=filters;
    [self connect];
    return self;
}

-(NSArray *)normalizedFilters
{
    NSMutableArray *normalized=[NSMutableArray array];
    for (int i=0;i<self.filters.count;i++) {
        MPWStream *s=self.filters[i];
        if ( [s target]==self.target || ((i<self.filters.count-1) && [s target]==self.filters[i+1])) {
            [s setTarget:nil];
        }
        while (s && [s respondsToSelector:@selector(target)] && s!=self.target) {
            [normalized addObject:s];
            s=[s target];
        }
    }
    return normalized;
}


-(void)connect
{
    self.filters=[self normalizedFilters];
    if ( self.filters.count > 1) {
        for (int i=0; i<self.filters.count-1;i++) {
            [self.filters[i] setTarget:self.filters[i+1]];
        }
    }
    [self.filters.lastObject setTarget:[self target]];
}

-(void)setTarget:(id <Streaming>)newTarget
{
    [[[self filters] lastObject] setTarget:nil];
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

-(int)inflight
{
    int inflight=0;
//    NSLog(@"inflight status for filters: %@",self.filters);
    for ( id s in self.filters) {
        if ( [s respondsToSelector:@selector(inflight)]) {
            inflight+=[s inflight];
        }
    }
    return inflight;
}

-(void)setHeaderDict:aDict
{
    for ( id s in self.filters) {
        if ( [s respondsToSelector:@selector(setHeaderDict:)]) {
            [s setHeaderDict:aDict];
        }
    }
}


-(void)addFilter:(id <Streaming>)newFilter
{
    self.filters = [self.filters arrayByAddingObject:newFilter];
    [self connect];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: filters: %@ target: %@>",[self class],self,self.filters,self.target];
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

+(void)testMulteElementStreamCanBeAddedToPipe
{
    MPWStream *first=[MPWMessageFilterStream streamWithSelector:@selector(uppercaseString)];
    MPWStream *second=[MPWBlockFilterStream streamWithBlock:^(NSString *s){ return [s stringByAppendingString:@" World!"];}];
    MPWStream *third=[MPWBlockFilterStream streamWithBlock:^(NSString *s){ return [s stringByAppendingString:@" Moon!"];}];
    [first setTarget:second];
    
        NSArray *filters =
    @[
        first,third
      ];
    MPWPipe *pipe=[[self alloc] initWithFilters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([[pipe target] firstObject], @"HELLO World! Moon!", @"hello world, processed");
}

+(NSArray *)testSelectors
{
    return @[
             @"testBasicPipe",
             @"testMulteElementStreamCanBeAddedToPipe",
             ];
}




@end