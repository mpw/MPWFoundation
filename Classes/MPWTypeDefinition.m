//
//  MPWTypeDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import "MPWTypeDefinition.h"

@interface MPWTypeDefinition ()

@property (nonatomic, assign) unsigned char objcTypeCode;
@property (nonatomic, strong) NSString *cName;

@end

#define TYPE_FLAG_INVISIBLE      1

@implementation MPWTypeDefinition
{
    unsigned long flags;
}

flagAccessor(invisible, setInvisible, flags, TYPE_FLAG_INVISIBLE)
longAccessor(flags, setFlags)



-(BOOL)visible
{
    return !(self.invisible || self.objcTypeCode == '#' );
}

static MPWTypeDefinition* typesByObjCCode[256];
static NSDictionary *typesBySTName;

+(instancetype)descriptorForObjcCode:(unsigned char)typeCode
{
    return typesByObjCCode[typeCode];
}

+(instancetype)descriptorForTypeName:(NSString*)typeName
{
    MPWTypeDefinition *td = typesBySTName[typeName];
    if ( !td ) {
        td=[[MPWTypeDefinition new] autorelease];
        td.objcTypeCode='@';
        td.name=typeName;
        td.cName=[typeName stringByAppendingString:@"*"];
    }
    return td;
}

typedef struct {
    unsigned char objcTypeCode;
    char *name;
    char *cName;
    long flags;
} STTypeDescriptorStruct;



static STTypeDescriptorStruct definedTypes[]={
    { '@', "id", "id",0 },
    { 'l', "int", "long",0 },
    { 'B', "bool", "BOOL" },
    { 'd', "float", "double" },
    
    { 's', "int", "short" },
    { 'S', "int", "unsigned short" },
    { 'i', "int", "int" },
    { 'q', "long", "long long" },
    { 'I', "int", "unsigned" },
    { 'Q', "long", "unsigned long long" },
    { 'L', "long", "unsigned long" },
    { '*', "str", "char*" },
    { 'v', "void", "void" },
    { ':', "SEL", "SEL" },
    { '#', "class", "Class" },
    { 0, NULL,NULL},
};

static STTypeDescriptorStruct mdaTypes[]={
    { '@', "Text" ,"id" , 0 },
    { '@', "Date" ,"id" , 0 },
    { 'q', "oid" ,"long" , TYPE_FLAG_INVISIBLE },
    { 0, NULL , 0},
};


+(void)initialize
{
    NSMutableDictionary *st2type=[NSMutableDictionary dictionary];
    for (int i=0; definedTypes[i].objcTypeCode;i++) {
        MPWTypeDefinition *descriptor=[MPWTypeDefinition new];
        descriptor.objcTypeCode=definedTypes[i].objcTypeCode;
        descriptor.name=@(definedTypes[i].name);
        descriptor.cName=@(definedTypes[i].cName);
        descriptor.flags=definedTypes[i].flags;
        typesByObjCCode[definedTypes[i].objcTypeCode]=descriptor;
    }
    //   MDA types are not entered into the objcTypeCode → type map, because they share
    for (int i=0; mdaTypes[i].objcTypeCode;i++) {
        MPWTypeDefinition *descriptor=[MPWTypeDefinition new];
        descriptor.objcTypeCode=mdaTypes[i].objcTypeCode;
        descriptor.name=@(mdaTypes[i].name);
        descriptor.cName=@(mdaTypes[i].cName);
        descriptor.flags=definedTypes[i].flags;
        st2type[descriptor.name]=descriptor;
    }
    unsigned char sttypes[]="@ldvB";
    for (int i=0;sttypes[i];i++) {
        MPWTypeDefinition *t=typesByObjCCode[sttypes[i]];
        st2type[t.name]=t;
    }
    typesBySTName=[st2type copy];
}

+(instancetype)voidType
{
    return [self descriptorForObjcCode:'v'];
}

+(instancetype)idType
{
    return [self descriptorForObjcCode:'@'];
}

+(instancetype)int64Type
{
    return [self descriptorForObjcCode:'l'];
}

-(NSString *)description
{
    return self.name;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTypeDefinition(testing) 

+(void)testKnowsAboutID
{
    MPWTypeDefinition *idDescriptor=[self descriptorForObjcCode:'@'];
    
    IDEXPECT( idDescriptor.name, @"id", @"stName");
    IDEXPECT( idDescriptor.cName, @"id", @"stName");
    INTEXPECT( idDescriptor.objcTypeCode, '@', @"type code");
}

+(void)testKnowsAboutMDATextType
{
    MPWTypeDefinition *idDescriptor=[self descriptorForTypeName:@"Text"];
    
    IDEXPECT( idDescriptor.name, @"Text", @"stName");
    IDEXPECT( idDescriptor.cName, @"id", @"stName");
    INTEXPECT( idDescriptor.objcTypeCode, '@', @"type code");
}

+(void)testMapsSTIntNameToLong
{
    MPWTypeDefinition *idDescriptor=[self descriptorForTypeName:@"int"];
    
    IDEXPECT( idDescriptor.name, @"int", @"stName");
    IDEXPECT( idDescriptor.cName, @"long", @"stName");
    INTEXPECT( idDescriptor.objcTypeCode, 'l', @"type code");
}

+(void)testUnknownTypeNamesAreObjects
{
    MPWTypeDefinition *idDescriptor=[self descriptorForTypeName:@"NSString"];
    
    IDEXPECT( idDescriptor.name, @"NSString", @"stName");
    IDEXPECT( idDescriptor.cName, @"NSString*", @"cName");
    INTEXPECT( idDescriptor.objcTypeCode, '@', @"type code");
}

+(void)testKnowsAboutObjectIds
{
    MPWTypeDefinition *idDescriptor=[self descriptorForTypeName:@"oid"];
    
    IDEXPECT( idDescriptor.name, @"oid", @"stName");
    IDEXPECT( idDescriptor.cName, @"long", @"cName");
    INTEXPECT( idDescriptor.objcTypeCode, 'q', @"type code");
    EXPECTTRUE(idDescriptor.invisible,@"visibility");
    EXPECTFALSE(idDescriptor.visible,@"visibility");
}

+(NSArray*)testSelectors
{
    return @[
        @"testKnowsAboutID",
        @"testKnowsAboutMDATextType",
        @"testKnowsAboutObjectIds",
        @"testMapsSTIntNameToLong",
        @"testUnknownTypeNamesAreObjects",
    ];
}

@end
