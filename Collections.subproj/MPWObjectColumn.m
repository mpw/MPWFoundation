//
//  MPWObjectColumn.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 31.03.26.
//

#import "MPWObjectColumn.h"

@implementation MPWObjectColumn

-(id)objectAtIndex:(NSUInteger)anIndex
{
    return [self.objects[anIndex] valueForKey:self.key];
}

-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:newObject
{
    [self.objects[anIndex] setValue:newObject forKey:self.key];
}



@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWObjectColumn(testing) 

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
