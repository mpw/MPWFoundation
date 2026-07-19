//
//  MPWForm.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.05.26.
//

#import "MPWForm.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWForm


-(void)dealloc
{
    [_def release];
    [_formAction release];
    [_store release];
    [super  dealloc];
}

-(void)generateHtml:aStream
{
    [aStream writeForm:self];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWForm(testing) 

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
