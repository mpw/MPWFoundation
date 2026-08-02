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


-(void)setTarget:aTarget
{
    [super setTarget:aTarget];
    Class targetClass = [aTarget class];
    if ( ![aTarget isKindOfClass:[MPWByteStream class]]) {
        targetClass = [MPWByteStream class];
    }
    self.temp  = [targetClass streamWithTarget:[NSMutableString string]];
}

-(void)writeNSObject:(id)anObject
{
    [[self.temp target] setString:[NSMutableString string]];
    [self.temp writeObject:anObject sender:nil];
    [(MPWByteStream*)(self.target) writeData:[[self.temp target] asData]];
    [(MPWByteStream*)(self.target) appendBytes:"\n" length:1];
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
