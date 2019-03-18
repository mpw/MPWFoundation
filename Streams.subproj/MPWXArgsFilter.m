//
//  MPWXArgsFilter.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 18.03.19.
//

#import "MPWXArgsFilter.h"

@implementation MPWXArgsFilter

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
    NSTask *task=[NSTask launchedTaskWithExecutableURL:[self executableURL] arguments:@[ aString] error:nil terminationHandler:^(NSTask * _Nonnull aTask) {
        FORWARD(@"terminated");
    }];
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
