//
//  MPWStructureDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWStructureDefinition.h"
#import "AccessorMacros.h"
#import "MPWVariableDefinition.h"

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

-(MPWVariableDefinition*)fieldForName:(NSString*)name
{
    for ( MPWVariableDefinition *vardef in self.fields) {
        if ( [vardef.name isEqual:name]) {
            return vardef;
        }
    }
    return nil;
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
    MPWStructureDefinition *copy=[[[self class] alloc] initWithName:self.name fields:newFields];
    copy.documentation=self.documentation;
    return copy;
}

-(void)addReferencePathsTo:(NSMutableArray<NSString*>*)paths prefix:(NSString*)prefix
{
    for (MPWVariableDefinition *field in self.fields) {
        NSString *path=prefix.length ? [prefix stringByAppendingPathComponent:field.name] : field.name;
        if ([field.type isKindOfClass:[MPWStructureDefinition class]]) {
            [(MPWStructureDefinition*)field.type addReferencePathsTo:paths prefix:path];
        } else {
            [paths addObject:path];
        }
    }
}

-(NSArray<NSString*>*)referencePaths
{
    NSMutableArray *paths=[NSMutableArray array];
    [self addReferencePathsTo:paths prefix:@""];
    return paths;
}


-(void)dealloc
{
    [_fields release];
    [_documentation release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStructureDefinition(testing) 

+(void)testNestedReferencePaths
{
	MPWStructureDefinition *products=[self structureWithName:@"Products" fields:@[
        [MPWVariableDefinition idWithName:@"index.html"]
    ]];
    MPWVariableDefinition *productsField=[[[MPWVariableDefinition alloc] initWithName:@"Products" type:products] autorelease];
    MPWStructureDefinition *site=[self structureWithName:@"site" fields:@[
        [MPWVariableDefinition idWithName:@"index.html"], productsField
    ]];
    IDEXPECT([site referencePaths], (@[ @"index.html", @"Products/index.html" ]), @"nested fields describe store paths");
}

+(NSArray*)testSelectors
{
   return @[
			@"testNestedReferencePaths",
			];
}

@end
