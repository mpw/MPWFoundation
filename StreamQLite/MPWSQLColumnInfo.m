//
//  MPWSQLColumnInfo.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import "MPWSQLColumnInfo.h"
#import "AccessorMacros.h"
#import "MPWTypeDefinition.h"


@implementation MPWSQLColumnInfo

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: name: '%@' type: '%@' %@ %@",self.class,self,self.name,self.type,self.pk ? @"PRIMARY KEY":@"",self.notnull ? @"NOTNULL":@""];
}

-(MPWTypeDefinition*)baseType
{
    return [super type];
}

-(MPWTypeDefinition*)computeTypeFromSQL
{
    MPWTypeDefinition *computed=[MPWTypeDefinition idType];
    NSString *sqltype = self.sqlType;
    if ( self.pk && [sqltype isEqual:@"INTEGER"]) {
        computed=[MPWTypeDefinition descriptorForTypeName:@"oid"];
    }
    return computed;
}

-(MPWTypeDefinition*)type
{
    if ( ![self baseType]) {
        [self setType:[self computeTypeFromSQL]];
    }
    return [self baseType];
}


-(NSString*)objcType
{
    return @"@";
}

-(void)dealloc
{
    [self.sqlType release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSQLColumnInfo(testing) 

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
