//
//  MPWStructValue.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 08.04.26.
//

#import "MPWStructValue.h"
#import "MPWStructureDefinition.h"
#import "MPWInstanceVariableDefinition.h"
#import "MPWTypeDefinition.h"


@interface MPWStructValue()

@property (nonatomic, strong) MPWStructureDefinition *structure;

@end

@implementation MPWStructValue
{
    void *pointerToStruct;
}

CONVENIENCEANDINIT(structValue, WithPointer:(void*)newPtr definition:(MPWStructureDefinition*)newDef)
{
    if (self=[super init]) {
        pointerToStruct=newPtr;
        self.structure = newDef;
    }
    return self;
}

-(double)doubleAt:(NSString*)key
{
    for (MPWInstanceVariableDefinition *def in self.structure.fields) {
        if ( [def.name isEqual:key] ) {
            double *ptr=[def pointerToVarRelativeToBase:pointerToStruct];
            return *ptr;
        }
    }
    [NSException raise:@"notfound" format:@"key %@ not found",key];
}

-(void)dealloc{
    [_structure release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStructValue(testing) 

+(void)testRetrieveValuesFromRect
{
    NSRect testRect=NSMakeRect( 20, 10, 100, 300);
    MPWTypeDefinition* doubleDef=[MPWTypeDefinition descriptorForObjcCode:'d'];
    MPWInstanceVariableDefinition *xdef = [[[MPWInstanceVariableDefinition alloc] initWithName:@"x" offset:0 type:doubleDef] autorelease];
    MPWInstanceVariableDefinition *ydef = [[[MPWInstanceVariableDefinition alloc] initWithName:@"y" offset:8 type:doubleDef] autorelease];
    MPWInstanceVariableDefinition *wdef = [[[MPWInstanceVariableDefinition alloc] initWithName:@"w" offset:16 type:doubleDef] autorelease];
    MPWInstanceVariableDefinition *hdef = [[[MPWInstanceVariableDefinition alloc] initWithName:@"h" offset:24 type:doubleDef] autorelease];
    MPWStructureDefinition *rectStruct = [MPWStructureDefinition structureWithName:@"rect" fields:@[ xdef, ydef, wdef, hdef ]];
    
    MPWStructValue *s=[self structValueWithPointer:&testRect definition:rectStruct];
    FLOATEXPECT([s doubleAt:@"x"], 20, @"x");
    FLOATEXPECT([s doubleAt:@"y"], 10, @"x");
    FLOATEXPECT([s doubleAt:@"w"], 100, @"x");
    FLOATEXPECT([s doubleAt:@"h"], 300, @"x");
}

+(NSArray*)testSelectors
{
   return @[
			@"testRetrieveValuesFromRect",
			];
}

@end
