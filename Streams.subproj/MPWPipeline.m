//
//  MPWPipeline.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/05/16.
//
//

#import "MPWPipeline.h"
#import "MPWScatterStream.h"
#import "MPWExternalFilter.h"
#import "MPWActionStreamAdapter.h"
#import "MPWMapFilter.h"
#import "NSObjectFiltering.h"
#import <objc/runtime.h>

@interface MPWPipeline()

@property (nonatomic, strong) NSArray *filters;


@end


@implementation MPWPipeline

+(instancetype)filters:(NSArray *)filters
{
    return [[[self alloc] initWithFilters:filters] autorelease];
}


-(instancetype)initWithProcessedFilters:(NSArray *)filters
{
    self=[super initWithTarget:[NSMutableArray array]];
    self.filters=filters;
    [self connect];
    return self;
}

- (void)dealloc
{
    [_filters release];
    [super dealloc];
}

-(MPWWriteStream *)processFilterSpec:filter
{
    if ( [filter isKindOfClass:[NSString class]]) {
        if ( [(NSString*)filter hasPrefix:@"-"]) {
            SEL selector=NSSelectorFromString([filter substringFromIndex:1]);
            if (selector) {
                filter=[MPWMapFilter filterWithSelector:selector];
            } else {
                [NSException raise:@"SelectorNotFound" format:@"%@ selector not found: %@",[self class],filter];
            }
        } else if ( [(NSString*)filter hasPrefix:@"["] && [(NSString*)filter hasSuffix:@"]"]) {
            NSString *key=[filter substringWithRange:NSMakeRange(1, [filter length]-2)];
            filter=[MPWMapFilter filterWithBlock:[[^(id o){ return [o objectForKey:key]; } copy] autorelease]];
        } else if ( [(NSString*)filter hasPrefix:@"%"]) {
            NSString *formatString=[filter substringWithRange:NSMakeRange(1, [filter length]-1)];
            filter=[MPWMapFilter filterWithBlock:[[^(NSString *s){
                return [NSString stringWithFormat:formatString,s];
                        } copy] autorelease]];
            NSLog(@"got block filter %@ setTarget",filter);
            [filter setTarget:nil];
            NSLog(@"did setTarget on block filter");
        } else if ( [(NSString*)filter hasPrefix:@"!"]) {
            NSString *command=[filter substringWithRange:NSMakeRange(1, [filter length]-1)];
            filter=[NSClassFromString(@"MPWExternalFilter") filterWithCommandString:command];
            [filter setTarget:nil];
        } else {
            NSString *key=[filter copy];
            filter=[MPWMapFilter filterWithBlock:[[^(id o){ return [o valueForKey:key]; } copy] autorelease]];
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    } else if ( [filter respondsToSelector:@selector(value:)] ) {
        filter=[MPWMapFilter filterWithBlock:filter];
    } else if ( [filter respondsToSelector:@selector(setTarget:)] &&
                [filter respondsToSelector:@selector(setAction:)] &&
                [filter respondsToSelector:@selector(objectValue)] ) {
#pragma clang diagnostic pop
        filter=[[[MPWActionStreamAdapter alloc] initWithUIControl:filter target:nil] autorelease];
    } else if ( [filter respondsToSelector:@selector(streamWithTarget:)] ) {
        filter=[(Class)filter streamWithTarget:nil];
    } else if ( [filter isKindOfClass:[NSArray class]]) {
        NSArray *scatterTargetSpecs=(NSArray*)filter;
        NSMutableArray *scatterFilters=[NSMutableArray array];
        for ( id fspec in scatterTargetSpecs) {
            if ( [fspec isKindOfClass:[NSArray class]]) {
                fspec=[[self class] filters:fspec];
            } else {
                fspec=[self processFilterSpec:fspec];
            }
            [scatterFilters addObject:fspec];
        }
        filter=[MPWScatterStream filters:scatterFilters];
    }
    return filter;
}


-(NSArray*)processFilters:(NSArray*)filters
{
    NSMutableArray *processedFilters=[NSMutableArray arrayWithCapacity:filters.count];
    for ( id filter in filters ) {
        [processedFilters addObject:[self processFilterSpec:filter]];
    }
    return processedFilters;
}

-(instancetype)initWithFilters:(NSArray *)filters
{
    return [self initWithProcessedFilters:[self processFilters:filters]];
}

-(instancetype)initWithArray:(NSArray *)filters
{
    return [self initWithFilters:filters];
}


-(NSArray *)normalizedFilters
{
    NSMutableArray *normalized=[NSMutableArray array];
    for (int i=0;i<self.filters.count;i++) {
        MPWFilter *s=self.filters[i];
        if ( [s target]==self.target || ((i<self.filters.count-1) && [s target]==self.filters[i+1])) {
            [s setTarget:nil];
        }
        while (s && [s respondsToSelector:@selector(target)] && s!=self.target) {
            [normalized addObject:s];
            s=(MPWFilter*)[s target];
        }
    }
    return normalized;
}

-(void)close
{
    // FIXME: workaround for HOM not working as desired on GNUstep
    [[self filters] makeObjectsPerformSelector:@selector(close)];
//    [[[self filters] do] close];
}

-(void)flush
{
    [[[self filters] do] flush];
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

-(void)setTarget:(MPWWriteStream*)newTarget
{
    [[[self filters] lastObject] setTarget:nil];
    [super setTarget:newTarget];
    [self connect];
}

-(void)writeObject:(id)anObject sender:aStream
{
    [self.filters.firstObject writeObject:anObject sender:aStream];
}

-(void)writeObject:(id)anObject
{
    [self.filters.firstObject writeObject:anObject sender:self];
}


-(void)setErrorTarget:newErrorTarget
{
    for ( id s in self.filters) {
        if ( [s respondsToSelector:@selector(setErrorTarget:)]) {
            [s setErrorTarget:newErrorTarget];
        }
    }
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
typedef id (^OneArgBlock)(id randomArgument);
typedef id (^ZeroArgBlock)(void);

+(void)initialize
{
    static int initialized=NO;
    if  ( !initialized) {
        Class blockClass=NSClassFromString(@"NSBlock");
        if (!blockClass) {
            blockClass=NSClassFromString(@"_NSBlock");
        }
        NSLog(@"blockClass: %@",blockClass);

        IMP theImp=imp_implementationWithBlock( ^(id blockSelf, id argument){ ((OneArgBlock)blockSelf)(argument); } );
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        class_addMethod(blockClass, @selector(value:), theImp, "@@:@");
#pragma clang diagnostic pop
        initialized=YES;
    }
}


-(void)run
{
    [self.filters.firstObject run];
}

-(void)runInThread
{
    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}

-(void)graphViz:(MPWByteStream*)output
{
    [self.filters.firstObject graphViz:output];
}

@end

#import "DebugMacros.h"
#import "MPWFlattenStream.h"

@implementation MPWPipeline(testing)

+(void)testBasicPipe
{
    NSArray *filters =
    @[
      [MPWMapFilter filterWithSelector:@selector(uppercaseString)],
      [MPWMapFilter filterWithBlock:^(NSString *s){ return [s stringByAppendingString:@" World!"]; }],
      ];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([pipe firstObject], @"HELLO World!", @"hello world, processed");
}

+(void)testMultiElementStreamCanBeAddedToPipe
{
    MPWFilter *first=[MPWMapFilter filterWithSelector:@selector(uppercaseString)];
    MPWFilter *second=[MPWMapFilter filterWithBlock:^(NSString *s){ return [s stringByAppendingString:@" World!"];}];
    MPWWriteStream *third=[MPWMapFilter filterWithBlock:^(NSString *s){ return [s stringByAppendingString:@" Moon!"];}];
    [first setTarget:second];
    
        NSArray *filters =
    @[
        first,third
      ];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([pipe firstObject], @"HELLO World! Moon!", @"hello world, processed");
}


+(void)testCanUseStringsToSpecifyMessageFilter
{
    NSArray *filters = @[ @"-uppercaseString"];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([pipe firstObject], @"HELLO", @"hello, processed");
}

+(void)testCanUseStringsToSpecifyValueForKey
{
    NSArray *filters = @[ @"uppercaseString"];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([pipe firstObject], @"HELLO", @"hello, processed");
}

+(void)testCanUseStringsToSpecifyObjectForKey
{
    NSArray *filters = @[ @"[key1]"];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@{ @"key1": @"Hello", @"key2": @"World"}];
    IDEXPECT([pipe firstObject], @"Hello", @"hello, extracted");
}

+(void)testCanUseBlockToSpecifyBlockFilter
{
    NSArray *filters =
    @[
      ^(NSString *s){ return [s stringByAppendingString:@" World!"]; },
       ];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@"Hello"];
    IDEXPECT([pipe firstObject], @"Hello World!", @"Hello world, processed");
}


+(void)testCanUseClassToSpecifyFilterOfThatClass
{
    NSArray *filters = @[[MPWFlattenStream class] ];
    MPWPipeline *pipe=[self filters:filters];
    [pipe writeObject:@[ @"Hello", @"World"]];
    IDEXPECT([pipe firstObject], @"Hello", @"Hello world, processed");
    IDEXPECT([pipe lastObject], @"World", @"Hello world, processed");
}

+(void)testCanUseNestedArrayToSpecifyFanout
{
    NSArray *filters = @[ @[ @"-uppercaseString", @"-lowercaseString"] ];
    MPWPipeline *pipe=[[[self alloc]  initWithFilters:filters] autorelease];
    NSMutableArray *target=[NSMutableArray array];
    [pipe.filters.lastObject setTarget:target];
    [pipe writeObject: @"Hello"];
    
    IDEXPECT([target firstObject], @"HELLO", @"processed by first branch");
    IDEXPECT([target lastObject], @"hello", @"processed by second branch");
}

+(void)testFanoutCanContainPipes
{
    NSArray *filters = @[
                         @[ @[ @"-uppercaseString", ],
                            @[ @"-lowercaseString", ^(NSString *s){ return [s stringByAppendingString:@" World!"]; } ],
                            ],
                         ];
    MPWPipeline *pipe=[[[self alloc]  initWithFilters:filters] autorelease];
    NSMutableArray *target=[NSMutableArray array];
    [pipe.filters.lastObject setTarget:target];
    [pipe writeObject: @"Hello"];
    
    IDEXPECT([target firstObject], @"HELLO", @"processed by first branch");
    IDEXPECT([target lastObject], @"hello World!", @"processed by second branch");
}


+(void)testToUpperWithExternalFilter
{
    MPWPipeline *pipe=[self filters:@[ @"!tr '[a-z]' '[A-Z]'" , @"-stringValue"]];
    [pipe writeObjectAndClose:@"Hello"];
    IDEXPECT([pipe firstObject], @"HELLO", @"hello, processed");
}

+(void)testRaiseOnUnknownSelector
{
    @try {
        [self filters:@[ @"-bozoStringStringNotASelector" ]];
        EXPECTFALSE(true, @"shouldn't get here");
    } @catch (NSException * e ){
        IDEXPECT( [e reason], @"SelectorNotFound",@"exception reason");
    }


}

+(void)testGraphVizOutput
{
    MPWPipeline *p1=[MPWPipeline filters:@[ [MPWFilter class], [MPWFilter class]]];
    IDEXPECT( [p1 graphViz], @"\"MPWFilter\"\n -> \"MPWFilter\"\n -> \"NSMutableArray\"\n", @"");


}


+(NSArray *)testSelectors
{
    return @[
             @"testBasicPipe",
             @"testMultiElementStreamCanBeAddedToPipe",
             @"testCanUseStringsToSpecifyMessageFilter",
             @"testCanUseStringsToSpecifyValueForKey",
             @"testCanUseStringsToSpecifyObjectForKey",
             @"testCanUseBlockToSpecifyBlockFilter",
             @"testCanUseClassToSpecifyFilterOfThatClass",
             @"testCanUseNestedArrayToSpecifyFanout",
             @"testFanoutCanContainPipes",
             @"testGraphVizOutput",
#if !TARGET_OS_IOS
             @"testToUpperWithExternalFilter",
#endif
//             @"testRaiseOnUnknownSelector",
             ];
}




@end


