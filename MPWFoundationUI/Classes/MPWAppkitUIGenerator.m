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

-(void)writeAppKitFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        if ( hasMoreThanOneField ) {
            [self beginHorizontal];
            [self label:aField.title ];
        }
        [self textField:aField.name];
        if ( hasMoreThanOneField ) {
            [self endView];
        }
    }
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

+(NSArray*)testSelectors
{
   return @[
			@"testCreateTableViewByWritingTable",
			];
}

@end
