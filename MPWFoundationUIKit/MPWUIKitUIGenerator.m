//
//  MPWUIKitUIGenerator.m
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import "MPWUIKitUIGenerator.h"

@implementation MPWUIKitUIGenerator


-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWUIKitUIGenerator(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
