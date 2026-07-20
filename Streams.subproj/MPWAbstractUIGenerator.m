//
//  MPWAbstractUIGenerator.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.26.
//

#import "MPWAbstractUIGenerator.h"

@implementation NSObject(UIGeneration)

-(void)generateUI:(MPWAbstractUIGenerator*)stream
{
    [self flattenStructureOntoStream:stream];
}

@end


@implementation MPWAbstractUIGenerator

-(SEL)streamWriterMessage
{
    return @selector(generateUI:);
}

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

-(void)beginView:aView
{
    FORWARD(aView);
    self.target=aView;
}



-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [NSException raise:@"unimplemented" format:@"%@ not implemented in %@",NSStringFromSelector(_cmd),[self className]];
}

// Presentation systems that can make a button override this;  the button is
// targeted at the form's -resetForm:, so the reset behaviour stays in the model.
-(void)writeResetButtonForForm:(MPWForm*)aForm
{
}

-(void)writeForm:(MPWForm*)aForm
{
    self.store = aForm.store;
    [self writeUIFormForStruct: aForm.def  postAction: aForm.formAction];
    if ( aForm.hasResetAction ) {
        [self writeResetButtonForForm:aForm];
    }
}

-(id)controlForType:(MPWTypeDefinition*)type
{
    return [self.type2view at:type.name];
}


-(void)dealloc
{
    [_type2view release];
    [_store release];
    [super dealloc];
}

@end

@implementation MPWTable(AppKitUI)

-(void)generateUI:(MPWAbstractUIGenerator*)stream
{
    [stream writeTable:self];
}

@end


@implementation MPWForm(AppKitUI)

-(void)generateUI:(MPWAbstractUIGenerator*)stream
{
    [stream writeForm:self];
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
