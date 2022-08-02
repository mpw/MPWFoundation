//
//  MPWPrintLiner.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.06.21.
//

#import "MPWPrintLiner.h"
#import "MPWByteStream.h"

@implementation MPWPrintLiner


-(void)writeNSObject:(id)anObject
{
    NSString *s=[anObject stringValue];
    NSLog(@"printlner: %@",s);
    [(MPWByteStream*)(self.target) println:s];
}

-(void)writeObject:(id)anObject sender:dummy
{
    NSString *s=[anObject stringValue];
    NSLog(@"printlner: %@",s);
    [(MPWByteStream*)(self.target) println:s];
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
