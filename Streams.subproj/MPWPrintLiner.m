//
//  MPWPrintLiner.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.06.21.
//

#import "MPWPrintLiner.h"
#import "MPWByteStream.h"

@interface MPWPrintLiner()

@property (nonatomic, strong) MPWByteStream *temp;

@end


@implementation MPWPrintLiner

-(instancetype)initWithTarget:(id)aTarget
{
    self = [super initWithTarget:aTarget];
    Class targetClass = [aTarget class];
    self.temp  = [[targetClass isKindOfClass:[MPWByteStream class]] ? targetClass : [MPWByteStream class] streamWithTarget:[NSMutableString string]];
    return self;
}

-(void)writeNSObject:(id)anObject
{
    [[self.temp target] setString:@""];
    [self.temp writeObject:anObject];
    [(MPWByteStream*)(self.target) println:[self.temp target]];
    [[self.temp target] setString:@""];
}

-(void)writeObject:(id)anObject sender:dummy
{
    [self writeNSObject:anObject];
}

-(void)writeObject:(id)anObject
{
    [self writeObject:anObject sender:nil];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWPrintLiner(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
