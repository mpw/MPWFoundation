//
//  MPWMessageFilterStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/15/12.
//
//

#import "MPWMessageFilterStream.h"
#import <objc/message.h>

@implementation MPWMessageFilterStream

scalarAccessor(SEL, selector, setSelector )

-(void)writeObject:(id)anObject sender:aSender
{
    [target writeObject:((IMP0)objc_msgSend)( anObject , selector) sender:aSender];
}

-(void)writeObject:(id)anObject
{
    [self writeObject:anObject sender:nil];
}

+(instancetype)streamWithSelector:(SEL)newSelector
{
    return [[[self alloc] initWithSelector:newSelector] autorelease];
}

-(instancetype)initWithSelector:(SEL)newSelector
{
    self=[super init];
    [self setSelector:newSelector];
    return self;
}

@end


@implementation MPWMessageFilterStream(testing)

+(void)testUppercase
{
    id stream=[self streamWithSelector:@selector(uppercaseString)];
    [stream writeObject:@"lower"];
    IDEXPECT([[stream target] lastObject],@"LOWER",@"uppercase of lower");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testUppercase",
            nil];
}

@end
