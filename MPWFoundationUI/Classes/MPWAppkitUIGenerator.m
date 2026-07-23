//
//  MPWAppkitUIGenertor.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import <Cocoa/Cocoa.h>       // before our header, which declares an NSView category
#import "MPWAppkitUIGenerator.h"
#import "MPWTableView.h"
#import "STTextField.h"
#import "STPopUpButton.h"
#import "STButton.h"
#import "STSlider.h"
#import "MPWIgnoreTrampoline.h"


@implementation NSObject(AppKitUI)

-(void)generateAppKitUI:(MPWAppkitUIGenerator*)stream
{
    [self generateUI:stream];
}

@end


@implementation MPWAppkitUIGenerator

+(MPWTypeToObjectMapper*)defaultTypes2UIMapper
{
    MPWTypeToObjectMapper *type2view = [[MPWTypeToObjectMapper new] autorelease];
    // Value-bearing controls are the store-bound ST* subclasses, so a generated
    // form's controls read from / write back to the storage combinator.
    type2view[@"bool"] = [STButton templateWithValues:@{ @"buttonType": @(NSButtonTypeSwitch), @"title": @"" }];
    //    type2view[@"id"] = [STTextField templateWithValues:@{ @"bezeled": @(true), @"bezelStyle": @(NSTextFieldRoundedBezel), @"editable": @(true) }];
    type2view[@"id"] = [STButton templateWithValues:@{ @"buttonType": @(NSButtonTypeMomentaryPushIn), @"title": @"" }];
    type2view[@"String"] = [STTextField templateWithValues:@{ @"bezeled": @(true), @"bezelStyle": @(NSTextFieldRoundedBezel), @"editable": @(true) }];
    type2view[@"Text"] = [NSTextView templateWithValues:@{ }];
    type2view[@"Date"] = [STTextField templateWithValues:@{ @"bezeled": @(true), @"bezelStyle": @(NSTextFieldRoundedBezel), @"editable": @(true) }];
    type2view[@"enumeration"] = [STPopUpButton templateWithValues:@{ }];
    type2view[@"Horizontal"] = [NSStackView templateWithValues:@{ @"orientation": @(NSUserInterfaceLayoutOrientationHorizontal) }];
    type2view[@"Vertical"] = [NSStackView templateWithValues:@{ @"orientation": @(NSUserInterfaceLayoutOrientationVertical) }];
    return type2view;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.valueControlMinimumWidth = 280;
    self.contentInset = 24;
    self.contentSpacing = 24;
    self.destructiveActionColor = [NSColor systemRedColor];
    if ( [aTarget respondsToSelector:@selector(addArrangedSubview:)] ) {
        self.rootView = aTarget;            // arranges generated views itself
    } else {
        // A plain container (a view controller's view, say): generating into it
        // directly would just pile up unconstrained subviews, so create the
        // top-level stack and constrain it inside what we were given.
        self.baseView = aTarget;
        self.rootView = [self rootViewInBaseView:aTarget];
        self.target = self.rootView;
    }
    return self;
}

// Centered horizontally, attached to the top, and inset on the other edges, so
// the form keeps its natural size and stays put when the base view resizes.
-(NSView*)rootViewInBaseView:(NSView*)base
{
    NSStackView *stack = [[self class] defaultTarget];
    stack.alignment = NSLayoutAttributeCenterX;
    stack.spacing = self.contentSpacing;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [base addSubview:stack];
    CGFloat inset = self.contentInset;
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:base.centerXAnchor],
        [stack.topAnchor constraintEqualToAnchor:base.topAnchor constant:inset],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:base.leadingAnchor constant:inset],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:base.trailingAnchor constant:-inset],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:base.bottomAnchor constant:-inset],
    ]];
    return stack;
}

-(SEL)streamWriterMessage
{
    return @selector(generateAppKitUI:);
}

-(void)label:(NSString*)title
{
    [self writeObject:[NSTextField labelWithString:title]];
}

-(void)textField:(NSString*)title
{
    [self writeObject:[NSTextField textFieldWithString:@"title"]];
}

// Choose the control for a field: an enumeration (field.values) becomes a
// popup, otherwise the declared type drives the choice through the type mapper.
-(NSView*)controlForField:(MPWVariableDefinition*)field
{
    if ( field.values.count ) {
        STPopUpButton *popup = (STPopUpButton*)[self.type2view at:@"enumeration"];
        [popup addItemsWithTitles:field.values];
        return popup;
    }
    return [self controlForType:field.type];
}

// Bind a control to the field's value in the store, so edits write through the
// storage combinator and external model changes update the control.
-(void)bindControl:(NSControl*)control toField:(MPWVariableDefinition*)field
{
    BOOL editable = (field.operations & MPWRESTVerbsWrite) != 0;
    if ( self.store ) {
        if (  [control isKindOfClass:[NSButton class]] && field.type.objcTypeCode == '@' &&
             ![control isKindOfClass:[STPopUpButton class]] ) {
            id targetObject = self.store[field.name];
            [control setTarget:targetObject];
            [control setAction:@selector(inspect)];
            NSString *title=[targetObject description];
            title = title.length > 30 ? [title substringToIndex:25] : title;
            [control setTitle:title];
            [control setFrame:NSMakeRect(0,0,100,20)];
        } else if ( [control respondsToSelector:@selector(setBinding:)] ) {
            MPWReference *ref = [self.store bindingForReference:[self.store referenceForPath:field.name]];
            [(id)control setBinding:ref];
            if ( [control respondsToSelector:@selector(updateFromRef)] ) {
                [(id)control updateFromRef];        // initial population from the store
            }
        }
    }
    if ( !editable ) {
        [[(id)control ifResponds] setEnabled:NO];
        [[(id)control ifResponds] setEditable:NO];
    }
}

// Value controls size to their current contents, which makes a generated form
// collapse to whatever happens to be in the store.  Give the field-sized
// controls a minimum width so the form has a stable, readable width.  Toggles
// keep their intrinsic size.
-(void)applyMinimumWidthToControl:(NSView*)control
{
    if ( self.valueControlMinimumWidth > 0 &&
        ( [control isKindOfClass:[NSTextField class]] || [control isKindOfClass:[NSPopUpButton class]] )) {
        control.translatesAutoresizingMaskIntoConstraints = NO;
        [[control.widthAnchor constraintGreaterThanOrEqualToConstant:self.valueControlMinimumWidth] setActive:YES];
    }
}

-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    NSGridView *grid = [[[NSGridView alloc] initWithFrame:NSZeroRect] autorelease];
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        NSMutableArray *row=[NSMutableArray array];
        if ( hasMoreThanOneField ) {
            [row addObject:[NSTextField labelWithString:aField.title]];
        }
        NSView *control = [self controlForField:aField];
        [self bindControl:control toField:aField];
        [self applyMinimumWidthToControl:control];
        [row addObject:control];
        [grid addRowWithViews:row];
    }
    FORWARD(grid);
}

// Generated because the form says it has a reset action;  the button targets the
// form itself, which restores the defaults through the store.
-(void)writeResetButtonForForm:(MPWForm*)aForm
{
    NSButton *reset=[NSButton buttonWithTitle:aForm.resetTitle target:aForm action:@selector(resetForm:)];
    reset.bezelStyle = NSBezelStyleRounded;
    // Reset discards what the user entered, so tint it as destructive.  A bezeled
    // button's title ignores contentTintColor (that only tints template images),
    // so the title has to be colored via the attributed title.
    reset.contentTintColor = self.destructiveActionColor;
    reset.attributedTitle = [[[NSAttributedString alloc] initWithString:aForm.resetTitle
                                                            attributes:@{ NSForegroundColorAttributeName: self.destructiveActionColor }] autorelease];
    FORWARD(reset);
}

-(void)beginHorizontal
{
    [self beginView:[self.type2view at:@"Horizontal"]];
}

-(void)beginVertical
{
    [self beginView:[self.type2view at:@"Vertical"]];
}


-(void)endView
{
    self.target = (id)[(NSView*)(self.target) superview];
}


-(void)writeTable:(MPWTable*)table
{
    MPWTableView *view = [[[MPWTableView alloc] initWithFrame: NSMakeRect(0, 0, 200, 100)] autorelease];
    [view setTable:table];
    [view reloadData];
    FORWARD(view);
}

+(id)defaultTarget
{
    return [[[NSStackView alloc] initWithDictionary:@{ @"orientation": @(NSUserInterfaceLayoutOrientationVertical) }] autorelease];
}

-(void)dealloc
{
    // releasing rootView here crashes, it seems due to overrelease since rootView is an alias for target
    // but of course since it is strong that should also get an extra retain...weird
    // baseView is not the target, so it does need to be released here.
    [_baseView release];
    [_destructiveActionColor release];
    [super dealloc];
}

@end




@implementation NSView(streaming)

-(void)writeObject:aView
{
    [self addSubview:aView];
}

@end

@implementation NSView(UICreation)

-(MPWAppkitUIGenerator*)uiGenerator
{
    return [MPWAppkitUIGenerator streamWithTarget:self];
}

@end


@implementation NSStackView(streaming)

-(void)writeObject:aView
{
    [self addArrangedSubview:aView];
}

@end


@implementation NSObject(inspector)

-(NSView*)inspector
{
    return [MPWAppkitUIGenerator process:[self form]];
}

-(void)inspect
{
    [[self inspector] openInWindow:[self className]];
}

@end

@implementation NSArray(insepector)

-table
{
    return [[[MPWObjectArrayTable alloc] initWithObjects:self] autorelease];
}

-(NSView*)inspector
{
    return [MPWAppkitUIGenerator process:[self table]];
}



@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWAppkitUIGenerator(testing) 



+(void)testCreateTableViewByWritingTable
{
    MPWDictArrayTable *table=[[[MPWDictArrayTable alloc] initWithObjects:@[ @{ @"first": @"Marcel"  }, @{ @"last":  @"Weiher"} ] ] autorelease];
    NSStackView *container = [self process:table];
    EXPECTTRUE( [container isKindOfClass:[NSStackView class]],@"got the containing stack");
    INTEXPECT( [container orientation], NSUserInterfaceLayoutOrientationVertical,@"vertical");
    MPWTableView *tableview = [[container subviews] lastObject];
    EXPECTNOTNIL(tableview,@"got a table view");
    EXPECTTRUE( [tableview isKindOfClass:[MPWTableView class]],@"got a table view");
}

+(void)testMapAppKitTypes
{
    MPWAppkitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];
    EXPECTTRUE( [[generator controlForType:types[@"String"]] isKindOfClass:[NSTextField class]], @"String to text field");
    EXPECTTRUE( [[generator controlForType:types[@"id"]] isKindOfClass:[NSButton class]], @"default button");
    EXPECTTRUE( [[generator controlForType:types[@"bool"]] isKindOfClass:[NSButton class]], @"bool to checkbox");
}

+(void)testCreateForm
{
    MPWAppkitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];

    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"todo" fields:@[
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Title" type:types[@"String"]] autorelease],
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Done" type:types[@"bool"]] autorelease],
    ]] autorelease];
    MPWForm *form=[[[MPWForm alloc] initWithDictionary:@{ @"def": structure, @"formAction": @"/newTask"}] autorelease];

    NSStackView *container = [generator process:form];
    EXPECTTRUE( [container isKindOfClass:[NSStackView class]],@"got the containing stack");
    INTEXPECT( [container orientation], NSUserInterfaceLayoutOrientationVertical,@"vertical");
    NSArray *formviews = [container subviews];
    INTEXPECT( formviews.count, 1, @"form elements");
    NSView* formTopLevel = [formviews lastObject];
    EXPECTTRUE( [formTopLevel isKindOfClass:[NSGridView class]],@"got the containing grid");
    NSArray* formElements = [formTopLevel subviews];
    INTEXPECT( formElements.count, 4, @"form elements");
    EXPECTTRUE( [formElements[0] isKindOfClass:[NSTextField class]], @"first label is a text field");
    EXPECTTRUE( [formElements[1] isKindOfClass:[NSTextField class]], @"first field is a text field");
    EXPECTTRUE( [formElements[2] isKindOfClass:[NSTextField class]], @"second label is a text field");
    EXPECTTRUE( [formElements[3] isKindOfClass:[NSButton class]], @"second field is a (checkbox) button");

}

// A model-driven form bound to a storage combinator: controls are populated
// from the store and edits write back through it — all without UIKit/AppKit
// view-controller glue.
+(void)testBoundFormReadsAndWritesThroughStore
{
    MPWTypeStore *types=[MPWTypeStore store];
    MPWVariableDefinition *nameField=[[[MPWVariableDefinition alloc] initWithName:@"name" type:types[@"String"]] autorelease];
    MPWVariableDefinition *activeField=[[[MPWVariableDefinition alloc] initWithName:@"active" type:types[@"bool"]] autorelease];
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"person" fields:@[nameField,activeField]] autorelease];

    MPWRawDictStore *store=[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionaryWithDictionary:@{ @"name": @"Ada", @"active": @YES }]];
    MPWForm *form=[[[MPWForm alloc] init] autorelease];
    form.def = structure;
    form.store = store;

    MPWAppkitUIGenerator *generator=[self stream];
    NSStackView *container=[generator process:form];
    NSGridView *grid=[[container subviews] lastObject];
    EXPECTTRUE( [grid isKindOfClass:[NSGridView class]], @"got the form grid");
    INTEXPECT( grid.numberOfRows, 2, @"one row per structure field");

    STTextField *nameControl=(STTextField*)[grid cellAtColumnIndex:1 rowIndex:0].contentView;
    EXPECTTRUE( [nameControl isKindOfClass:[STTextField class]], @"name field is an STTextField");
    IDEXPECT( nameControl.stringValue, @"Ada", @"name control populated from the store");

    nameControl.stringValue = @"Grace";
    [nameControl updateToRef];
    IDEXPECT( [store at:[store referenceForPath:@"name"]], @"Grace", @"text edit written through the store");

    STButton *activeControl=(STButton*)[grid cellAtColumnIndex:1 rowIndex:1].contentView;
    EXPECTTRUE( [activeControl isKindOfClass:[STButton class]], @"bool field is an STButton");
    INTEXPECT( activeControl.state, NSControlStateValueOn, @"bool control populated from the store");
    activeControl.state = NSControlStateValueOff;
    [activeControl updateToRef];
    INTEXPECT( [[store at:[store referenceForPath:@"active"]] boolValue], NO, @"bool edit written through the store");
}

+(void)testEnumerationFieldBecomesBoundPopup
{
    MPWTypeStore *types=[MPWTypeStore store];
    MPWVariableDefinition *freq=[[[MPWVariableDefinition alloc] initWithName:@"frequency" type:types[@"id"]] autorelease];
    freq.values = @[ @"Daily", @"Weekly", @"Monthly" ];
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"prefs" fields:@[freq]] autorelease];
    MPWRawDictStore *store=[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionaryWithDictionary:@{ @"frequency": @"Weekly" }]];
    MPWForm *form=[[[MPWForm alloc] init] autorelease];
    form.def=structure; form.store=store;

    MPWAppkitUIGenerator *generator=[self stream];
    NSStackView *container=[generator process:form];
    NSGridView *grid=[[container subviews] lastObject];
    STPopUpButton *popup=(STPopUpButton*)[grid cellAtColumnIndex:0 rowIndex:0].contentView;
    EXPECTTRUE( [popup isKindOfClass:[STPopUpButton class]], @"a field with allowed values becomes a popup");
    INTEXPECT( popup.numberOfItems, 3, @"popup carries the field's allowed values");
    IDEXPECT( popup.ref.value , @"Weekly", @"ref value");
    IDEXPECT( popup.titleOfSelectedItem, @"Weekly", @"popup selection populated from the store");
    [popup selectItemWithTitle:@"Monthly"];
    [popup updateToRef];
    IDEXPECT( [store at:[store referenceForPath:@"frequency"]], @"Monthly", @"popup selection written through the store");
}

// The reset button is part of the generated form, driven by the model's
// hasResetAction flag, and resetting goes through the store and the
// ModelDidChange notification back into the bound controls.
+(void)testFormWithResetActionGeneratesConnectedResetButton
{
    MPWTypeStore *types=[MPWTypeStore store];
    MPWVariableDefinition *nameField=[[[MPWVariableDefinition alloc] initWithName:@"name" type:types[@"String"]] autorelease];
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"person" fields:@[nameField]] autorelease];
    MPWForm *form=[[[MPWForm alloc] init] autorelease];
    form.def=structure;
    form.store=[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionaryWithDictionary:@{ @"name": @"Ada" }]];
    form.defaultStore=[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionaryWithDictionary:@{ @"name": @"Default" }]];
    form.hasResetAction=YES;

    NSStackView *container=[[self stream] process:form];
    NSArray *formviews=[container subviews];
    INTEXPECT( formviews.count, 2, @"grid plus reset button");
    NSButton *reset=[formviews lastObject];
    EXPECTTRUE( [reset isKindOfClass:[NSButton class]], @"reset is a button");
    IDEXPECT( reset.title, @"Reset", @"default reset title");
    PTREXPECT( reset.target, form, @"button targets the form");
    EXPECTTRUE( reset.action == @selector(resetForm:), @"button connected to resetForm:");
    IDEXPECT( reset.contentTintColor, [NSColor systemRedColor], @"reset is styled as destructive");
    IDEXPECT( [reset.attributedTitle attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
             [NSColor systemRedColor], @"reset title is drawn in the destructive color");

    NSGridView *grid=[formviews firstObject];
    STTextField *nameControl=(STTextField*)[grid cellAtColumnIndex:0 rowIndex:0].contentView;
    IDEXPECT( nameControl.stringValue, @"Ada", @"control populated from the store");

    [reset performClick:nil];
    IDEXPECT( [form.store at:[form.store referenceForPath:@"name"]], @"Default", @"default written through the store");
    IDEXPECT( nameControl.stringValue, @"Default", @"control updated from the store after reset");
}

+(void)testFormWithoutResetActionHasNoResetButton
{
    MPWTypeStore *types=[MPWTypeStore store];
    MPWVariableDefinition *nameField=[[[MPWVariableDefinition alloc] initWithName:@"name" type:types[@"id"]] autorelease];
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"person" fields:@[nameField]] autorelease];
    MPWForm *form=[[[MPWForm alloc] init] autorelease];
    form.def=structure;

    NSStackView *container=[[self stream] process:form];
    INTEXPECT( [[container subviews] count], 1, @"just the grid");
}

// Generating straight into a plain container view: the generator creates and
// constrains the top-level stack, so a client just writes the form to its view.
+(void)testGeneratingIntoPlainBaseViewCreatesConstrainedRootView
{
    MPWTypeStore *types=[MPWTypeStore store];
    MPWVariableDefinition *nameField=[[[MPWVariableDefinition alloc] initWithName:@"name" type:types[@"id"]] autorelease];
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"person" fields:@[nameField]] autorelease];
    MPWForm *form=[[[MPWForm alloc] init] autorelease];
    form.def=structure;

    NSView *base=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,400,300)] autorelease];
    MPWAppkitUIGenerator *generator=[base uiGenerator];
    PTREXPECT( generator.baseView, base, @"the view we were handed is the base view");
    EXPECTTRUE( generator.rootView != base, @"root view is created, not the base view");
    [generator process:form];

    INTEXPECT( [[base subviews] count], 1, @"just the created root view");
    NSStackView *root=(NSStackView*)[[base subviews] lastObject];
    PTREXPECT( root, generator.rootView, @"root view was added to the base view");
    EXPECTTRUE( [root isKindOfClass:[NSStackView class]], @"root view is a stack view");
    EXPECTFALSE( root.translatesAutoresizingMaskIntoConstraints, @"root view is laid out by constraints");
    EXPECTTRUE( base.constraints.count > 0, @"root view is constrained in the base view");
    EXPECTTRUE( [[[root subviews] lastObject] isKindOfClass:[NSGridView class]], @"form was generated into the root view");
}

// A view that arranges what we generate is used as-is, without wrapping.
+(void)testGeneratingIntoStackViewUsesItAsRootView
{
    NSStackView *stack=[[[NSStackView alloc] initWithFrame:NSZeroRect] autorelease];
    MPWAppkitUIGenerator *generator=[stack uiGenerator];
    EXPECTNIL( generator.baseView, @"no separate base view needed");
    PTREXPECT( generator.rootView, stack, @"the stack view we were handed is the root view");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCreateTableViewByWritingTable",
       @"testCreateForm",
       @"testMapAppKitTypes",
       @"testBoundFormReadsAndWritesThroughStore",
       @"testEnumerationFieldBecomesBoundPopup",
       @"testFormWithResetActionGeneratesConnectedResetButton",
       @"testFormWithoutResetActionHasNoResetButton",
       @"testGeneratingIntoPlainBaseViewCreatesConstrainedRootView",
       @"testGeneratingIntoStackViewUsesItAsRootView",
			];
}

@end

