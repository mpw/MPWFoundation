//
//  MPWInstanceVarStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 29.04.24.
//

#import "MPWInstanceVarStore.h"

@implementation MPWInstanceVarStore

-(MPWDirectoryReference*)computeListOfProperties
{
    NSArray *names = (NSArray*)[[[[self.object class] instanceVariables] collect] name];
    NSArray *refs=(NSArray*)[[self collect] referenceForPath:[names each]];
    return [[[MPWDirectoryReference alloc] initWithContents:refs] autorelease];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWInstanceVarStore(testing) 

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
