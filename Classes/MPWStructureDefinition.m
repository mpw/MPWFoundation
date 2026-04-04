//
//  MPWStructureDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWStructureDefinition.h"
#import "AccessorMacros.h"

@implementation MPWStructureDefinition

CONVENIENCEANDINIT( structure, WithName:(NSString*)newName fields:newFields )
{
    self=[super init];
    self.name = newName;
    self.fields = newFields;
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: name: %@ fields: %@>",
            [self className],self,self.name,self.fields];
}

-(void)dealloc
{
    [_fields release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStructureDefinition(testing) 

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
