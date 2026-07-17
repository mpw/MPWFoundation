//
//  MPWUIKitUIGenerator.m
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import "MPWUIKitUIGenerator.h"
#import <UIKit/UIKit.h>

@interface MPWUIKitEmailField : UITextField
@end

@implementation MPWUIKitEmailField
/// FIXME:
///  this only exists because the templating mechanism apparently cannot set the keyboardType
///    KVC fails, says that this is an unknown key

-(instancetype)init
{
    self=[super init];
    if (self) {
        self.borderStyle=UITextBorderStyleBezel;
        self.keyboardType=UIKeyboardTypeEmailAddress;
        self.textContentType=UITextContentTypeEmailAddress;
        self.autocapitalizationType=UITextAutocapitalizationTypeNone;
        self.autocorrectionType=UITextAutocorrectionTypeNo;
    }
    return self;
}

@end


@interface MPWUIKitValueButton : UIButton
@property (nonatomic,retain) id representedValue;
@property (nonatomic,assign) BOOL appendsDisclosureIndicator;
@property (nonatomic,assign) BOOL preservesConfiguredTitle;
@property (nonatomic,retain) NSArray *allowedValues;
@property (nonatomic,retain) NSArray *displayValues;
@end

@implementation MPWUIKitValueButton

-(id)objectValue { return self.representedValue; }

-(void)setObjectValue:(id)value
{
    self.representedValue=value;
    if (self.preservesConfiguredTitle && (![value respondsToSelector:@selector(length)] || [value length] == 0)) { return; }
    NSString *title=(value && value != [NSNull null]) ? [value description] : @"";
    NSUInteger mappedIndex=[self.allowedValues indexOfObject:value];
    if (mappedIndex != NSNotFound && mappedIndex < self.displayValues.count) {
        title=[self.displayValues[mappedIndex] description];
    }
    if (self.appendsDisclosureIndicator && title.length) { title=[title stringByAppendingString:@"  ›"]; }
    [self setTitle:title forState:UIControlStateNormal];
}

-(void)setValueEditable:(BOOL)editable { self.enabled=editable; }

-(void)dealloc
{
    [_representedValue release];
    [_allowedValues release];
    [_displayValues release];
    [super dealloc];
}

@end


@implementation NSObject(AppKitUI)

-(void)generateUIKitUI:(MPWUIKitUIGenerator*)stream
{
    [self generateUI:stream];
}

@end

// Type mapping is another stream stage: the mapped object is written back to
// the generator so it may itself participate in polymorphic UI generation.
@implementation MPWTypeDefinition(UIKitUI)

-(void)generateUIKitUI:(MPWUIKitUIGenerator*)stream
{
    id mapped=[stream.type2view atType:self];
    if (mapped) { [stream writeObject:mapped]; }
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
    type2view[@"bool"] = [UISwitch templateWithValues:@{ }];
    type2view[@"id"] = [UITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"EmailAddress"] = [MPWUIKitEmailField templateWithValues:@{ }];
    type2view[@"Date"] = [UITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"Text"] = [UITextView templateWithValues:@{ }];
    type2view[@"int"] = [UITextField templateWithValues:@{ @"borderStyle": @(UITextBorderStyleRoundedRect), @"keyboardType": @(UIKeyboardTypeNumberPad) }];
    type2view[@"long"] = [UITextField templateWithValues:@{ @"borderStyle": @(UITextBorderStyleRoundedRect), @"keyboardType": @(UIKeyboardTypeNumberPad) }];
    type2view[@"float"] = [UITextField templateWithValues:@{ @"borderStyle": @(UITextBorderStyleRoundedRect), @"keyboardType": @(UIKeyboardTypeDecimalPad) }];
    type2view[@"Horizontal"] = [UIStackView templateWithValues:@{ @"axis": @(UILayoutConstraintAxisHorizontal) }];
    type2view[@"Vertical"] = [UIStackView templateWithValues:@{ @"axis": @(UILayoutConstraintAxisVertical) }];
    return type2view;
}

+(UIView*)mappedControlForType:(MPWTypeDefinition*)type typeMapper:(MPWTypeToObjectMapper*)typeMapper
{
    if (!type) { return nil; }
    NSMutableArray *result=[NSMutableArray array];
    MPWUIKitUIGenerator *generator=[[[self alloc] initWithTarget:result] autorelease];
    generator.type2view=typeMapper;
    [generator writeObject:type];
    return result.lastObject;
}

-(id)controlForType:(MPWTypeDefinition*)type
{
    return [[self class] mappedControlForType:type typeMapper:self.type2view];
}

+(UIView*)controlForType:(MPWTypeDefinition*)type
    presentationMetadata:(NSDictionary*)metadata
              typeMapper:(MPWTypeToObjectMapper*)typeMapper
{
    return [self controlForType:type
           presentationMetadata:metadata
              representedObject:nil
                     typeMapper:typeMapper];
}

+(UIView*)controlForType:(MPWTypeDefinition*)type
    presentationMetadata:(NSDictionary*)metadata
       representedObject:(id)representedObject
              typeMapper:(MPWTypeToObjectMapper*)typeMapper
{
    metadata=metadata ?: @{};
    NSString *kind=metadata[MPWPresentationControlKey];
    NSArray *allowed=metadata[MPWPresentationAllowedValuesKey];
    NSArray *display=metadata[MPWPresentationDisplayValuesKey] ?: allowed;
    UIView *control=nil;

    if ([kind isEqual:@"label"] || [kind isEqual:@"value"]) {
        UILabel *label=[[[UILabel alloc] init] autorelease];
        label.numberOfLines=[type.name isEqual:@"Text"] ? 0 : 1;
        label.adjustsFontForContentSizeCategory=YES;
        label.textColor=[kind isEqual:@"value"] ? [UIColor secondaryLabelColor] : [UIColor labelColor];
        control=label;
    } else if ([kind isEqual:@"segmented"] || (!kind && allowed.count > 0)) {
        UISegmentedControl *segments=[[[UISegmentedControl alloc] initWithItems:display ?: @[]] autorelease];
        control=segments;
    } else if ([kind isEqual:@"disclosure"] || [kind isEqual:@"menu"] || [kind isEqual:@"action"]) {
        MPWUIKitValueButton *button=[MPWUIKitValueButton buttonWithType:UIButtonTypeSystem];
        button.contentHorizontalAlignment=[kind isEqual:@"action"] ? UIControlContentHorizontalAlignmentCenter : UIControlContentHorizontalAlignmentRight;
        button.appendsDisclosureIndicator=[kind isEqual:@"disclosure"] || [kind isEqual:@"menu"];
        button.preservesConfiguredTitle=[kind isEqual:@"action"];
        button.allowedValues=allowed;
        button.displayValues=display;
        if ([kind isEqual:@"action"]) {
            NSString *title=[representedObject respondsToSelector:@selector(title)] ? [representedObject title] : @"";
            [button setTitle:title ?: @"" forState:UIControlStateNormal];
            if ([metadata[MPWPresentationDestructiveKey] boolValue]) { [button setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal]; }
        }
        if ([kind isEqual:@"menu"] && allowed.count) {
            if (@available(iOS 14.0, *)) {
                NSMutableArray *actions=[NSMutableArray array];
                __unsafe_unretained MPWUIKitValueButton *unretainedButton=button;
                [allowed enumerateObjectsUsingBlock:^(id value, NSUInteger index, BOOL *stop) {
                    NSString *title=index < display.count ? [display[index] description] : [value description];
                    UIAction *action=[UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction *selectedAction) {
                        [unretainedButton setObjectValue:value];
                        [unretainedButton sendActionsForControlEvents:UIControlEventValueChanged];
                    }];
                    [actions addObject:action];
                }];
                button.menu=[UIMenu menuWithTitle:@"" children:actions];
                button.showsMenuAsPrimaryAction=YES;
            }
        }
        control=button;
    } else {
        control=[self mappedControlForType:type typeMapper:typeMapper];
    }

    if (!control) {
        UILabel *fallback=[[[UILabel alloc] init] autorelease];
        fallback.adjustsFontForContentSizeCategory=YES;
        control=fallback;
    }
    if ([control isKindOfClass:[UITextField class]]) {
        UITextField *field=(id)control;
        field.placeholder=metadata[MPWPresentationPlaceholderKey];
    }
    return control;
}

-(void)endView
{
    self.target = (id)[(UIView*)(self.target) superview];
}


-(void)writeUIFormForStructVH:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [self beginView:self.type2view[@"Vertical"]];
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        [self beginView:self.type2view[@"Horizontal"]];
        if ( hasMoreThanOneField ) {
            [self writeObject:[[[UILabel alloc] initWithDictionary: @{ @"text": aField.title}] autorelease]];
        }
        [self writeObject:[self controlForType:aField.type]];
        [self endView];
    }
    [self writeObject:[UIView new]];
    [self endView];
}


-(void)writeUIFormForStructVV:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        [self writeObject:[[[UILabel alloc] initWithDictionary: @{ @"text": aField.title}] autorelease]];
        [self writeObject:[self controlForType:aField.type]];
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
