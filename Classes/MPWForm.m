//
//  MPWForm.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.05.26.
//

#import "MPWForm.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWForm

-(NSString*)resetTitle
{
    return _resetTitle ?: @"Reset";
}

// Values live in the store under their leaf names, so nested structures are
// descended into rather than looked up.
-(void)resetFieldsOfStructure:(MPWStructureDefinition*)structure
{
    for ( MPWVariableDefinition *field in structure.fields ) {
        if ( [field.type isKindOfClass:[MPWStructureDefinition class]] ) {
            [self resetFieldsOfStructure:(MPWStructureDefinition*)field.type];
        } else {
            id defaultValue=[self.defaultStore at:[self.defaultStore referenceForPath:field.name]];
            if ( defaultValue ) {
                [self.store at:[self.store referenceForPath:field.name] put:defaultValue];
            }
        }
    }
}

// Copy the defaults through the store, then tell the bound controls the model
// changed;  they re-read themselves from their references, so no view walking
// and no per-field callbacks are needed here.
-(IBAction)resetForm:(id)sender
{
    if ( !self.defaultStore || !self.store ) {
        return;
    }
    [self resetFieldsOfStructure:self.def];
    sendProtocolNotification( @protocol(ModelDidChange), self );
}


-(IBAction)submitForm:(id)sender
{
    // ?
}


-(void)dealloc
{
    [_def release];
    [_formAction release];
    [_resetTitle release];
    [_store release];
    [_defaultStore release];
    [super  dealloc];
}

-(void)generateHtml:aStream
{
    [aStream writeForm:self];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWForm(testing) 

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
