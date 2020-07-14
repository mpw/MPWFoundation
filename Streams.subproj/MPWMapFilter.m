//
//  MPWMapFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/11/18.
//

#import "MPWMapFilter.h"
#import <AccessorMacros.h>
#import <objc/message.h>

@interface NSObject(value)

-value:arg;

@end

@interface MPWMapFilter()

@property (nonatomic, strong) id block;

@end


@implementation MPWMapFilter

CONVENIENCEANDINIT( filter, WithSelector:(SEL)aSelector)
{
    return [self initWithBlock:[[^(id anObject){ ((IMP0)objc_msgSend)( anObject , aSelector);} copy] autorelease]];
}

CONVENIENCEANDINIT( filter, WithBlock:(id)aBlock)
{
    self=[super init];
    self.block=aBlock;
    return self;
}


typedef id (^filterBlock)(id);

-(void)writeObject:(id)anObject sender:(id)sourceStream
{
    filterBlock localBlock=_block;
    if ( localBlock){
        FORWARD(  localBlock(anObject) );
    }
}

-(void)dealloc
{
    [_block release];
    [super dealloc];
}

@end


#import "DebugMacros.h"

@implementation MPWMapFilter(testing)

+(void)testUppercaseMessage
{
    id stream=[self filterWithSelector:@selector(uppercaseString)];
    [stream writeObject:@"lower"];
    IDEXPECT([[stream target] lastObject],@"LOWER",@"uppercase of lower");
}


+(void)testUppercaseBlock
{
    id stream=[self filterWithBlock:^(id input){ return [input uppercaseString];}];
    [stream writeObject:@"lower"];
    IDEXPECT([[stream target] lastObject], @"LOWER", @"lower as uppercase after filtering");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testUppercaseMessage",
            @"testUppercaseBlock",
            nil];
}

@end
