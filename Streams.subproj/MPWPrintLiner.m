//
//  MPWPrintLiner.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.06.21.
//

#import "MPWPrintLiner.h"

@implementation MPWPrintLiner

-(void)writeObject:(id)anObject sender:dummy
{
    NSString *s=[anObject stringValue];
    [self.target println:s];
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
