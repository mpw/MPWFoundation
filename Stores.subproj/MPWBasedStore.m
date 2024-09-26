//
//  MPWBasedStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26.09.24.
//

#import "MPWBasedStore.h"
#import "MPWValueReference.h"

@interface MPWBasedStore()


@end

@implementation MPWBasedStore
@dynamic baseObject;

-(instancetype)initWithValue:aValue
{
    self=[super init];
    self.baseObject = aValue;
    return self;
}

-(void)setBaseObject:(id)baseObject
{
    self.baseReference = [MPWValueReference value:baseObject];
}

-(id)baseObject
{
    return [self.baseReference value];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWBasedStore(testing) 

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
