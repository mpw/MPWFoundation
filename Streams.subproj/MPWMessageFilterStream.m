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

-(void)writeObject:(id)anObject
{
    [target writeObject:((IMP0)objc_msgSend)( anObject , selector)];
}


@end


@implementation MPWMessageFilterStream(testing)

+(void)testUppercase
{
    id stream=[self stream];
    [stream setSelector:@selector(uppercaseString)];
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