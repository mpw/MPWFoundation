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
    [self flattenStructureOntoStream:stream];
}

@end


@implementation MPWAppkitUIGenerator

+(MPWTypeToObjectMapper*)defaultTypes2AppKitMapper
{
    MPWTypeToObjectMapper *type2view = [[MPWTypeToObjectMapper new] autorelease];
    type2view[@"bool"] = [NSButton templateWithValues:@{ @"buttonType": @(NSButtonTypeSwitch),@"title": @"" }];
    type2view[@"id"] = [NSTextField templateWithValues:@{ @"bezeled": @(false) }];
    type2view[@"Text"] = [NSTextView templateWithValues:@{ }];
    type2view[@"Date"] = [NSTextField templateWithValues:@{ @"bezeled": @(false) }];
    return type2view;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.rootView = aTarget;
    self.type2view = [self.class defaultTypes2AppKitMapper];
    return self;
}

-(SEL)streamWriterMessage
{
    return @selector(generateAppKitUI:);
}

-(void)beginView:aView
{
    FORWARD(aView);
    self.target=aView;
}

-(void)label:(NSString*)title
{
    [self writeObject:[NSTextField labelWithString:title]];
}

-(void)textField:(NSString*)title
{
    [self writeObject:[NSTextField textFieldWithString:@"title"]];
}

-(id)controlForType:(MPWTypeDefinition*)type
{
    return [self.type2view at:type.name];
}

-(void)writeAppKitFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
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

-(void)writeForm:(MPWForm*)aForm
{
    [self writeAppKitFormForStruct: aForm.def  postAction: aForm.formAction];
    
}

-(void)beginHorizontal
{
    [self beginView:[[[NSStackView alloc] initWithDictionary:@{ @"orientation": @(NSUserInterfaceLayoutOrientationHorizontal) }] autorelease]];
}


-(void)endView
{
    self.target = [self.target superview];
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
    [_rootView dealloc];
    [super dealloc];
}

@end



@implementation MPWTable(AppKitUI)

-(void)generateAppKitUI:(MPWAppkitUIGenerator*)stream
{
    [stream writeTable:self];
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

+(void)testMapTypes
{
    MPWAppkitUIGenerator *generator=[self stream];
    MPWTypeToObjectMapper *mapper=generator.type2view;
    MPWTypeStore *types=[MPWTypeStore store];
    EXPECTTRUE( [[mapper atType:types[@"id"]] isKindOfClass:[NSTextField class]], @"default text field");
    EXPECTTRUE( [[mapper atType:types[@"bool"]] isKindOfClass:[NSButton class]], @"bool to checkbox");
}


+(NSArray*)testSelectors
{
   return @[
			@"testCreateTableViewByWritingTable",
            @"testMapTypes",
			];
}

@end

