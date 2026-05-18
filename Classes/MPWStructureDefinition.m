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

-concat:anItem
{
    [self.fields addObject:anItem];
    return self;
}


CONVENIENCEANDINIT( structure, WithName:(NSString*)newName dict:(NSDictionary*)dict )
{
    NSArray *allKeys=[dict allKeys];
    NSMutableArray *fields=[NSMutableArray array];
    for (NSString *key in allKeys) {
        MPWVariableDefinition *def=[[[MPWVariableDefinition alloc] initWithName:key type:[MPWTypeDefinition idType]] autorelease];
        [fields addObject:def];
    }
    return [self initWithName:newName fields:fields];
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: name: %@ fields: %@>",
            [self className],self,self.name,self.fields];
}

-(instancetype)copyWithFieldIndexes:(NSArray <NSNumber*> *)fieldIndexes
{
    NSMutableArray *newFields=[NSMutableArray array];
    for (long i=0,max=[fieldIndexes count];i<max;i++) {
        [newFields addObject:[[self.fields[ fieldIndexes[i].intValue ] copy] autorelease]];
    }
    return [[[self class] alloc] initWithName:self.name fields:newFields];
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
