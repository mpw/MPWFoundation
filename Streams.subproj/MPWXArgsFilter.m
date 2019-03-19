//
//  MPWXArgsFilter.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 18.03.19.
//

#import "MPWXArgsFilter.h"

#if !TARGET_OS_IPHONE

@interface NSObject(writeOnXArgsFilter)

-(void)writeOnXArgsFilter:aFilter;

@end


@interface  MPWXArgsFilter()

@property (nonatomic, retain) NSMutableArray *additionalArgs;

@end

@implementation MPWXArgsFilter

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.additionalArgs=[NSMutableArray array];
    return self;
}

-(NSArray*)allArgs
{
    NSArray *allArgs = [[super allArgs] arrayByAddingObjectsFromArray:self.additionalArgs];
    return allArgs;
}


-(SEL)streamWriterMessage
{
    return @selector(writeOnXArgsFilter:);
}


-(NSURL*)executableURL
{
    return [NSURL fileURLWithPath:@"/bin/echo"];
}

-(void)writeString:(NSString*)aString
{
    if (!self.additionalArgs) {
        self.additionalArgs=[NSMutableArray array];
    }
    [self.additionalArgs addObject:aString];
    [self run];
    [self flushLocal];
    [self.additionalArgs removeAllObjects];
}


@end


@implementation NSObject(writeOnXArgsFilter)

-(void)writeOnXArgsFilter:aFilter
{
    [self writeOnStream:aFilter];
}

@end

@implementation NSString(writeOnXArgsFilter)

-(void)writeOnXArgsFilter:aFilter
{
    [aFilter writeString:self];
}

@end

@implementation MPWBinding(writeOnXArgsFilter)

-(void)writeOnXArgsFilter:aFilter
{
    [aFilter writeString:self.path];
}

@end

#import "DebugMacros.h"


@implementation MPWXArgsFilter(testing)

+(void)testEcho
{
    //    MPWExternalFilter *filter=[self filterWithCommandString:@"tr '[a-z]' '[A-Z]'"];
    MPWXArgsFilter *filter=[self filterWithCommand:@"/bin/echo" args:@[]];
    NSArray *result = [NSMutableArray array];
    [filter setTarget:(id)result];
    [filter writeString:@"hello world!"];
    [filter writeString:@"more hello!"];
    [filter close];
    IDEXPECT( [[(id)[filter target] firstObject] stringValue],@"hello world!\n",@"some echoing" );
    IDEXPECT( [[(id)[filter target] lastObject] stringValue],@"more hello!\n",@"some echoing" );
}

+(void)testEchoWithArg
{
    //    MPWExternalFilter *filter=[self filterWithCommandString:@"tr '[a-z]' '[A-Z]'"];
    MPWXArgsFilter *filter=[self filterWithCommand:@"/bin/echo" args:@[ @"-n" ]];
    NSArray *result = [NSMutableArray array];
    [filter setTarget:(id)result];
    [filter writeString:@"hello world!"];
    [filter writeString:@"more hello!"];
    [filter close];
    IDEXPECT( [[(id)[filter target] firstObject] stringValue],@"hello world!",@"some echoing" );
    IDEXPECT( [[(id)[filter target] lastObject] stringValue],@"more hello!",@"some echoing" );
}

+testSelectors {
    return @[
             @"testEcho",
             @"testEchoWithArg",
             ];
}

@end

#endif
