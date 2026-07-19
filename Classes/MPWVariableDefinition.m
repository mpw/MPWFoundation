//
//  MPWVariableDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWVariableDefinition.h"
#import "MPWTypeDefinition.h"

@implementation MPWVariableDefinition
{
    NSString *title;
}

lazyAccessor(NSString*, title, setTitle, computeTitle )

@dynamic title;

-initWithName:(NSString*)newName type:(MPWTypeDefinition*)newType
{
    self=[super init];
    self.name = newName;
    self.type = newType;
    self.operations = MPWRESTVerbsReadWrite;
    return self;
}

+(instancetype)idWithName:(NSString*)newName
{
    return [[[self alloc] initWithName:newName type:[MPWTypeDefinition idType]] autorelease];
}

+(instancetype)int64WithName:(NSString*)newName
{
    return [[[self alloc] initWithName:newName type:[MPWTypeDefinition int64Type]] autorelease];
}

-(NSString*)computeTitle
{
    return [self.name capitalizedString];
}

-(NSString*)objcType
{
    return [NSString stringWithFormat:@"%c",self.objcTypeCode];
}

-(unsigned char)objcTypeCode
{
    return self.type.objcTypeCode;
}


-(void)dealloc
{
    [_name release];
    [_type release];
    [_defaultValue release];
    [_values release];
    [_presentationMetadata release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWVariableDefinition(testing) 

+(void)testRetainsDefaultValueAsFieldSemantics
{
    MPWVariableDefinition *field=[self idWithName:@"greeting"];
    field.defaultValue=@"hello";
    IDEXPECT(field.defaultValue,@"hello",@"default belongs to the field definition");
}

+(NSArray*)testSelectors
{
   return @[
            @"testRetainsDefaultValueAsFieldSemantics",
            ];
}

@end
