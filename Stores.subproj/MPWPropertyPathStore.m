//
//  MPWPropertyPathStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 06.06.23.
//

#import "MPWPropertyPathStore.h"
#import "MPWRESTOperation.h"

typedef struct {
    NSString *propertyPath;
    IMP  functions[MPWRESTVerbMAX];
} PropertyPathDef;

typedef struct {
    int count;
    PropertyPathDef defs[0];
} PropertyPathDefs;

@implementation MPWPropertyPathStore

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWPropertyPathStore(testing) 

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
