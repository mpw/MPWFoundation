//
//  MPWAppkitUIGenertor.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import "MPWAppkitUIGenerator.h"
#import "MPWTableView.h"
#import <Cocoa/Cocoa.h>

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
    type2view[@"bool"] = [NSButton templateWithValues:@{ @"buttonType": @(NSButtonTypeSwitch),@"title": @"" }];
    type2view[@"id"] = [NSTextField templateWithValues:@{ @"bezeled": @(false) }];
    type2view[@"Text"] = [NSTextView templateWithValues:@{ }];
    type2view[@"Date"] = [NSTextField templateWithValues:@{ @"bezeled": @(false) }];
    type2view[@"Horizontal"] = [NSStackView templateWithValues:@{ @"orientation": @(NSUserInterfaceLayoutOrientationHorizontal) }];
    type2view[@"Vertical"] = [NSStackView templateWithValues:@{ @"orientation": @(NSUserInterfaceLayoutOrientationVertical) }];
    return type2view;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.rootView = aTarget;
    return self;
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

-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    NSGridView *grid = [[[NSGridView alloc] initWithFrame:NSZeroRect] autorelease];
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        NSMutableArray *row=[NSMutableArray array];
        if ( hasMoreThanOneField ) {
            [row addObject:[NSTextField labelWithString:aField.title]];
        }
        [row addObject:[self controlForType:aField.type]];
        [grid addRowWithViews:row];
    }
    FORWARD(grid);
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
    [super dealloc];
}

@end




@implementation NSView(streaming)

-(void)writeObject:aView
{
    [self addSubview:aView];
}

@end

@implementation NSStackView(streaming)

-(void)writeObject:aView
{
    [self addArrangedSubview:aView];
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
    EXPECTTRUE( [[generator controlForType:types[@"id"]] isKindOfClass:[NSTextField class]], @"default text field");
    EXPECTTRUE( [[generator controlForType:types[@"bool"]] isKindOfClass:[NSButton class]], @"bool to checkbox");
}

+(void)testCreateForm
{
    MPWAppkitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];

    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"todo" fields:@[
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Title" type:types[@"id"]] autorelease],
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

+(NSArray*)testSelectors
{
   return @[
       @"testCreateTableViewByWritingTable",
       @"testCreateForm",
       @"testMapAppKitTypes",
			];
}

@end

