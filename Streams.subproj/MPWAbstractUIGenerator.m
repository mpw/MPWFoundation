//
//  MPWAbstractUIGenerator.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.26.
//

#import "MPWAbstractUIGenerator.h"

@implementation MPWAbstractUIGenerator

+(MPWTypeToObjectMapper*)defaultTypes2UIMapper
{
    MPWTypeToObjectMapper *type2view = [[MPWTypeToObjectMapper new] autorelease];
    return type2view;
}


-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.type2view = [self.class defaultTypes2UIMapper];
    return self;
}



-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [NSException raise:@"unimplemented" format:@"%@ not implemented in %@",NSStringFromSelector(_cmd),[self className]];
}

-(void)writeForm:(MPWForm*)aForm
{
    [self writeUIFormForStruct: aForm.def  postAction: aForm.formAction];
    
}

-(id)controlForType:(MPWTypeDefinition*)type
{
    return [self.type2view at:type.name];
}


-(void)dealloc
{
    [_type2view release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWAbstractUIGenerator(testing) 

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
