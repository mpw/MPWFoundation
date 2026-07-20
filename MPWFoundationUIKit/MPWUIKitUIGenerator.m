//
//  MPWUIKitUIGenerator.m
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import <UIKit/UIKit.h>
#import "MPWUIKitUIGenerator.h"
#import "MPWUIKitBoundControls.h"
#import "MPWTableView.h"

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

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.contentInset = 0;
    self.contentSpacing = 12;
    self.destructiveActionColor = [UIColor systemRedColor];
    self.formBackgroundColor = [UIColor systemGroupedBackgroundColor];
    if ( ![aTarget respondsToSelector:@selector(addArrangedSubview:)] && [aTarget isKindOfClass:[UIView class]] ) {
        // A plain container (a view controller's view, say): generating into it
        // directly would just pile up unconstrained subviews, so create the
        // top-level stack and constrain it inside what we were given.
        self.baseView = aTarget;
        self.target = [self rootViewInBaseView:aTarget];
    }
    return self;
}

// Fills the base view, inset by contentInset.  Top and sides go to the view's
// own edges so scrolling content passes under a navigation bar the way a system
// form does;  the bottom stops at the safe area so trailing controls stay clear
// of the home indicator.
-(UIView*)rootViewInBaseView:(UIView*)base
{
    UIStackView *stack = [[self class] defaultTarget];
    stack.spacing = self.contentSpacing;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    if ( !base.backgroundColor ) {
        base.backgroundColor = self.formBackgroundColor;
    }
    [base addSubview:stack];
    CGFloat inset = self.contentInset;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:base.topAnchor constant:inset],
        [stack.leadingAnchor constraintEqualToAnchor:base.leadingAnchor constant:inset],
        [stack.trailingAnchor constraintEqualToAnchor:base.trailingAnchor constant:-inset],
        [stack.bottomAnchor constraintEqualToAnchor:base.safeAreaLayoutGuide.bottomAnchor constant:-inset],
    ]];
    return stack;
}

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

// A form is written as the table projection of structure x store: that
// translation already turns nested structures into the sections — with their
// headers and documentation footers — a UIKit form is made of.
-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [self writeTable:[MPWStructureTable tableWithStructureDefinition:theStruct store:self.store]];
}

-(void)writeTable:(MPWTable*)table
{
    MPWTableView *view=[[[MPWTableView alloc] initWithFrame:CGRectZero] autorelease];
    view.presentationStyle = MPWTablePresentationStyleForm;
    [view setTable:table];
    FORWARD(view);
}

// Generated because the form says it has a reset action;  the button targets
// the form itself, which restores the defaults through the store.  Reset
// discards what the user entered, so it is tinted as destructive.
-(void)writeResetButtonForForm:(MPWForm*)aForm
{
    UIButton *reset=[UIButton buttonWithType:UIButtonTypeSystem];
    [reset setTitle:aForm.resetTitle forState:UIControlStateNormal];
    [reset setTitleColor:self.destructiveActionColor forState:UIControlStateNormal];
    [reset addTarget:aForm action:@selector(resetForm:) forControlEvents:UIControlEventTouchUpInside];
    [reset setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [reset setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    FORWARD(reset);
}

+(id)defaultTarget
{
    return [[[UIStackView alloc] initWithDictionary:@{ @"axis": @(UILayoutConstraintAxisVertical) }] autorelease];
}

-(UIView*)rootView
{
    return (UIView*)self.target;
}

-(void)dealloc
{
    [_baseView release];
    [_destructiveActionColor release];
    [_formBackgroundColor release];
    [super dealloc];
}

@end


@implementation UIView(UICreation)

-(MPWUIKitUIGenerator*)uiGenerator
{
    return [MPWUIKitUIGenerator streamWithTarget:self];
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

+(MPWForm*)settingsForm
{
    MPWTypeDefinition *stringType=[MPWTypeDefinition idType];
    MPWTypeDefinition *boolType=[MPWTypeDefinition descriptorForObjcCode:'B'];
    MPWVariableDefinition *name=[[[MPWVariableDefinition alloc] initWithName:@"name" type:stringType] autorelease];
    MPWVariableDefinition *sounds=[[[MPWVariableDefinition alloc] initWithName:@"sounds" type:boolType] autorelease];
    sounds.operations=MPWRESTVerbsReadWrite;
    MPWStructureDefinition *account=[MPWStructureDefinition structureWithName:@"account" fields:@[name]];
    MPWStructureDefinition *prefs=[MPWStructureDefinition structureWithName:@"preferences" fields:@[sounds]];
    prefs.documentation=@"Preferences footer.";
    MPWVariableDefinition *accountSection=[[[MPWVariableDefinition alloc] initWithName:@"account" type:account] autorelease];
    MPWVariableDefinition *prefsSection=[[[MPWVariableDefinition alloc] initWithName:@"preferences" type:prefs] autorelease];

    MPWForm *form=[[[MPWForm alloc] init] autorelease];
    form.def=[MPWStructureDefinition structureWithName:@"Settings" fields:@[accountSection,prefsSection]];
    form.store=[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionaryWithDictionary:@{ @"name": @"Ada", @"sounds": @YES }]];
    form.defaultStore=[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionaryWithDictionary:@{ @"name": @"Default", @"sounds": @NO }]];
    return form;
}

// A nested structure is written as a form-styled table view: the structure x
// store table projection turns each nested structure into a section.
+(void)testNestedStructureIsWrittenAsFormTable
{
    MPWForm *form=[self settingsForm];
    UIStackView *container=[[self stream] process:form];
    MPWTableView *tableview=[[container arrangedSubviews] lastObject];
    EXPECTTRUE( [tableview isKindOfClass:[MPWTableView class]], @"form is written as a table view");
    INTEXPECT( tableview.presentationStyle, MPWTablePresentationStyleForm, @"presented as a form");
    INTEXPECT( [tableview numberOfSectionsInCollectionView:tableview], 2, @"one section per nested structure");
}

+(void)testFormWithResetActionGeneratesConnectedResetButton
{
    MPWForm *form=[self settingsForm];
    form.hasResetAction=YES;

    UIStackView *container=[[self stream] process:form];
    NSArray *generated=[container arrangedSubviews];
    INTEXPECT( generated.count, 2, @"table view plus reset button");
    UIButton *reset=[generated lastObject];
    EXPECTTRUE( [reset isKindOfClass:[UIButton class]], @"reset is a button");
    IDEXPECT( [reset titleForState:UIControlStateNormal], @"Reset", @"default reset title");
    IDEXPECT( [reset titleColorForState:UIControlStateNormal], [UIColor systemRedColor], @"styled as destructive");
    IDEXPECT( [[reset actionsForTarget:form forControlEvent:UIControlEventTouchUpInside] lastObject],
             @"resetForm:", @"button connected to the form's resetForm:");

    // -sendActionsForControlEvents: is a no-op headless, so invoke the action.
    [form resetForm:reset];
    IDEXPECT( [form.store at:[form.store referenceForPath:@"name"]], @"Default", @"nested field reset through the store");
    INTEXPECT( [[form.store at:[form.store referenceForPath:@"sounds"]] boolValue], NO, @"second section reset too");
}

+(void)testFormWithoutResetActionHasNoResetButton
{
    UIStackView *container=[[self stream] process:[self settingsForm]];
    INTEXPECT( [[container arrangedSubviews] count], 1, @"just the table view");
}

// Generating straight into a plain container view: the generator creates and
// constrains the top-level stack, so a client just writes the form to its view.
+(void)testGeneratingIntoPlainBaseViewCreatesConstrainedRootView
{
    UIView *base=[[[UIView alloc] initWithFrame:CGRectMake(0,0,320,480)] autorelease];
    MPWUIKitUIGenerator *generator=[base uiGenerator];
    IDEXPECT( generator.baseView, base, @"the view we were handed is the base view");
    EXPECTTRUE( generator.rootView != base, @"root view is created, not the base view");
    [generator writeObject:[self settingsForm]];

    INTEXPECT( [[base subviews] count], 1, @"just the created root view");
    UIStackView *root=[[base subviews] lastObject];
    IDEXPECT( root, generator.rootView, @"root view was added to the base view");
    EXPECTTRUE( [root isKindOfClass:[UIStackView class]], @"root view is a stack view");
    EXPECTFALSE( root.translatesAutoresizingMaskIntoConstraints, @"root view is laid out by constraints");
    EXPECTTRUE( base.constraints.count > 0, @"root view is constrained in the base view");
    EXPECTTRUE( [[[root arrangedSubviews] lastObject] isKindOfClass:[MPWTableView class]], @"form was generated into the root view");
}

+(void)testGeneratingIntoStackViewUsesItAsRootView
{
    UIStackView *stack=[[[UIStackView alloc] initWithFrame:CGRectZero] autorelease];
    MPWUIKitUIGenerator *generator=[stack uiGenerator];
    EXPECTNIL( generator.baseView, @"no separate base view needed");
    IDEXPECT( generator.rootView, stack, @"the stack view we were handed is the root view");
}

+(NSArray*)testSelectors
{
    return @[
        @"testCreateForm",
        @"testMapUIKitTypes",
        @"testConcreteUIViewTerminatesMapping",
        @"testNestedStructureIsWrittenAsFormTable",
        @"testFormWithResetActionGeneratesConnectedResetButton",
        @"testFormWithoutResetActionHasNoResetButton",
        @"testGeneratingIntoPlainBaseViewCreatesConstrainedRootView",
        @"testGeneratingIntoStackViewUsesItAsRootView",
    ];
}

@end
