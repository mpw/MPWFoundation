//
//  MPWUIKitUIGenerator.m
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import "MPWUIKitUIGenerator.h"
#import "MPWUIKitBoundControls.h"
#import <UIKit/UIKit.h>

@implementation NSObject(AppKitUI)

-(void)generateUIKitUI:(MPWUIKitUIGenerator*)stream
{
    [self generateUI:stream];
}

@end

// A concrete view is an override and therefore terminates mapping.  Forward it
// unchanged to the current target instead of flattening its object structure.
@implementation UIView(UIKitUI)

-(void)generateUIKitUI:(MPWUIKitUIGenerator*)stream
{
    [stream forward:self];
}

@end


@implementation MPWUIKitUIGenerator


-(SEL)streamWriterMessage
{
    return @selector(generateUIKitUI:);
}



+(MPWTypeToObjectMapper*)defaultTypes2UIMapper
{
    MPWTypeToObjectMapper *type2view = [[MPWTypeToObjectMapper new] autorelease];
    // Value-bearing controls are the store-bound MPWUI* subclasses, so a
    // generated form's controls read from / write back to the store.
    type2view[@"bool"] = [MPWUISwitch templateWithValues:@{ }];
    type2view[@"id"] = [MPWUITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"String"] = [MPWUITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"EmailAddress"] = [MPWUIEmailField templateWithValues:@{ }];
    type2view[@"Date"] = [MPWUITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"Text"] = [MPWUITextView templateWithValues:@{ }];
    type2view[@"int"] = [MPWUITextField templateWithValues:@{ @"borderStyle": @(UITextBorderStyleRoundedRect), @"keyboardType": @(UIKeyboardTypeNumberPad) }];
    type2view[@"long"] = [MPWUITextField templateWithValues:@{ @"borderStyle": @(UITextBorderStyleRoundedRect), @"keyboardType": @(UIKeyboardTypeNumberPad) }];
    type2view[@"float"] = [MPWUITextField templateWithValues:@{ @"borderStyle": @(UITextBorderStyleRoundedRect), @"keyboardType": @(UIKeyboardTypeDecimalPad) }];
    type2view[@"Horizontal"] = [UIStackView templateWithValues:@{ @"axis": @(UILayoutConstraintAxisHorizontal) }];
    type2view[@"Vertical"] = [UIStackView templateWithValues:@{ @"axis": @(UILayoutConstraintAxisVertical) }];
    return type2view;
}

// Mapping a single component is a plain lookup in the type mapper, not a
// streaming operation: the stream is only for building nested structures.
-(id)controlForType:(MPWTypeDefinition*)type
{
    return type ? [self.type2view atType:type] : nil;
}

-(UIView*)controlForType:(MPWTypeDefinition*)type
    presentationMetadata:(NSDictionary*)metadata
{
    return [self controlForType:type presentationMetadata:metadata representedObject:nil];
}

-(UIView*)controlForType:(MPWTypeDefinition*)type
    presentationMetadata:(NSDictionary*)metadata
       representedObject:(id)representedObject
{
    metadata=metadata ?: @{};
    NSString *kind=metadata[MPWPresentationControlKey];
    NSArray *allowed=metadata[MPWPresentationAllowedValuesKey];
    NSArray *display=metadata[MPWPresentationDisplayValuesKey] ?: allowed;
    UIView *control=nil;

    if ([kind isEqual:@"label"] || [kind isEqual:@"value"]) {
        MPWUILabel *label=[[[MPWUILabel alloc] init] autorelease];
        label.numberOfLines=[type.name isEqual:@"Text"] ? 0 : 1;
        label.adjustsFontForContentSizeCategory=YES;
        label.textColor=[kind isEqual:@"value"] ? [UIColor secondaryLabelColor] : [UIColor labelColor];
        control=label;
    } else if ([kind isEqual:@"segmented"] || (!kind && allowed.count > 0)) {
        MPWUISegmentedControl *segments=[[[MPWUISegmentedControl alloc] initWithItems:display ?: @[]] autorelease];
        control=segments;
    } else if ([kind isEqual:@"disclosure"] || [kind isEqual:@"menu"] || [kind isEqual:@"action"]) {
        MPWUIValueButton *button=[MPWUIValueButton buttonWithType:UIButtonTypeSystem];
        button.contentHorizontalAlignment=[kind isEqual:@"action"] ? UIControlContentHorizontalAlignmentCenter : UIControlContentHorizontalAlignmentRight;
        button.appendsDisclosureIndicator=[kind isEqual:@"disclosure"] || [kind isEqual:@"menu"];
        button.preservesConfiguredTitle=[kind isEqual:@"action"];
        button.values=allowed;
        button.displayValues=display;
        if ([kind isEqual:@"action"]) {
            NSString *title=[representedObject respondsToSelector:@selector(title)] ? [representedObject title] : @"";
            [button setTitle:title ?: @"" forState:UIControlStateNormal];
            if ([metadata[MPWPresentationDestructiveKey] boolValue]) { [button setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal]; }
        }
        if ([kind isEqual:@"menu"]) { [button installValueMenu]; }
        control=button;
    } else {
        control=[self controlForType:type];
    }

    if (!control) {
        MPWUILabel *fallback=[[[MPWUILabel alloc] init] autorelease];
        fallback.adjustsFontForContentSizeCategory=YES;
        control=fallback;
    }
    if ([control isKindOfClass:[UITextField class]]) {
        UITextField *field=(id)control;
        field.placeholder=metadata[MPWPresentationPlaceholderKey];
    }
    return control;
}

#pragma mark - fields: control choice + store binding (mirrors the AppKit generator)

// A field with allowed `values` is an enumeration: present it as a menu button
// carrying those values.  Otherwise the declared type drives the mapper.
-(UIView*)controlForField:(MPWVariableDefinition*)field
{
    if ( field.values.count ) {
        MPWUIValueButton *button=[MPWUIValueButton buttonWithType:UIButtonTypeSystem];
        button.contentHorizontalAlignment=UIControlContentHorizontalAlignmentRight;
        button.appendsDisclosureIndicator=YES;
        button.values=field.values;
        button.displayValues=field.presentationMetadata[MPWPresentationDisplayValuesKey] ?: field.values;
        [button installValueMenu];
        return button;
    }
    return [self controlForType:field.type presentationMetadata:field.presentationMetadata];
}

// Bind the control to the field's value in the store, so edits write through
// the storage combinator and model changes update the control.
-(void)bindControl:(UIView*)control toField:(MPWVariableDefinition*)field
{
    BOOL editable = (field.operations & MPWRESTVerbsWrite) != 0;
    if ( self.store && [control respondsToSelector:@selector(setBinding:)] ) {
        MPWReference *ref=[self.store bindingForReference:[self.store referenceForPath:field.name]];
        [(id)control setBinding:ref];       // also populates from the store
    }
    if ( !editable ) {
        [control setValueEditable:NO];
    }
}

-(void)endView
{
    self.target = (id)[(UIView*)(self.target) superview];
}


// The stream is used purely to build the nested view structure: begin/end a
// stack, then write the already-mapped single components into it.
-(UIView*)labelForField:(MPWVariableDefinition*)aField
{
    return [[[MPWUILabel alloc] initWithDictionary: @{ @"text": aField.title ?: @""}] autorelease];
}

-(UIView*)boundControlForField:(MPWVariableDefinition*)aField
{
    UIView *control=[self controlForField:aField];
    [self bindControl:control toField:aField];
    return control;
}

-(void)writeUIFormForStructVH:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [self beginView:self.type2view[@"Vertical"]];
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        [self beginView:self.type2view[@"Horizontal"]];
        if ( hasMoreThanOneField ) {
            [self writeObject:[self labelForField:aField]];
        }
        [self writeObject:[self boundControlForField:aField]];
        [self endView];
    }
    [self writeObject:[UIView new]];
    [self endView];
}


-(void)writeUIFormForStructVV:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        [self writeObject:[self labelForField:aField]];
        [self writeObject:[self boundControlForField:aField]];
    }
    [self writeObject:[UIView new]];
}

-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [self writeUIFormForStructVV:theStruct postAction:actionString];
}

+(id)defaultTarget
{
    return [[[UIStackView alloc] initWithDictionary:@{ @"axis": @(UILayoutConstraintAxisVertical) }] autorelease];
}

-(UIView*)rootView
{
    return (UIView*)self.target;
}

@end


@implementation UIView(streaming)

-(void)writeObject:aView
{
    [self addSubview:aView];
}

@end

@implementation UIStackView(streaming)

-(void)writeObject:aView
{
    [self addArrangedSubview:aView];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWUIKitUIGenerator(testing) 

+(void)testMapUIKitTypes
{
    MPWUIKitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];
    EXPECTTRUE( [[generator controlForType:types[@"id"]] isKindOfClass:[UITextField class]], @"default text field");
    EXPECTTRUE( [[generator controlForType:types[@"bool"]] isKindOfClass:[UISwitch class]], @"bool to checkbox");
    UITextField *email=[generator controlForType:[MPWTypeDefinition descriptorForTypeName:@"EmailAddress"]];
    EXPECTTRUE([email isKindOfClass:[UITextField class]],@"semantic email type maps to text field");
    INTEXPECT(email.keyboardType,UIKeyboardTypeEmailAddress,@"semantic email type configures keyboard");
}

+(void)testConcreteUIViewTerminatesMapping
{
    NSMutableArray *target=[NSMutableArray array];
    MPWUIKitUIGenerator *generator=[self streamWithTarget:target];
    UIView *override=[[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [generator writeObject:override];
    IDEXPECT(target.lastObject,override,@"concrete UIView is forwarded unchanged");
}

+(void)testCreateForm
{
    MPWUIKitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];
    
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"todo" fields:@[
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Title" type:types[@"id"]] autorelease],
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Done" type:types[@"bool"]] autorelease],
    ]] autorelease];
    MPWForm *form=[[[MPWForm alloc] initWithDictionary:@{ @"def": structure, @"formAction": @"/newTask"}] autorelease];
    
    UIStackView *container = [generator process:form];
    EXPECTTRUE( [container isKindOfClass:[UIStackView class]],@"got the containing stack");
    INTEXPECT( [container axis], UILayoutConstraintAxisVertical,@"vertical");
//    UIView* formTopLevel = [container lastObject];
//    EXPECTTRUE( [formTopLevel isKindOfClass:[UIStackView class]],@"got the containing grid");
//    NSArray* formElements = [formTopLevel subviews];
//    INTEXPECT( formElements.count, 4, @"form elements");
//    EXPECTTRUE( [formElements[0] isKindOfClass:[UITextField class]], @"first label is a text field");
//    EXPECTTRUE( [formElements[1] isKindOfClass:[UITextField class]], @"first field is a text field");
//    EXPECTTRUE( [formElements[2] isKindOfClass:[UITextField class]], @"second label is a text field");
//    EXPECTTRUE( [formElements[3] isKindOfClass:[UIButton class]], @"second field is a (checkbox) button");
    
}

+(NSArray*)testSelectors
{
    return @[
        @"testCreateForm",
        @"testMapUIKitTypes",
        @"testConcreteUIViewTerminatesMapping",
    ];
}

@end
