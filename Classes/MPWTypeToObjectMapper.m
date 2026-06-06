//
//  MPWTypeToObjectMapper.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.26.
//

#import "MPWTypeToObjectMapper.h"

@interface MPWTypeToObjectMapper()

@property (nonatomic,strong) NSMutableDictionary<NSString*,MPWObjectTemplate*>*  typenameToObject;

@end


@implementation MPWTypeToObjectMapper

-(void)at:(NSString*)name put:template
{
    self.typenameToObject[name] = template;
}

-(instancetype)init
{
    self=[super init];
    self.typenameToObject = [NSMutableDictionary dictionary];
    return self;
}

-(id)at:typeName
{
    return [self.typenameToObject[typeName] object];
}

-(id)atType:(MPWTypeDefinition*)type
{
    return [self at:type.name];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTypeToObjectMapper(testing) 

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
