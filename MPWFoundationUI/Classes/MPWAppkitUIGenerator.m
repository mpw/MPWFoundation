//
//  MPWAppkitUIGenertor.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import "MPWAppkitUIGenerator.h"
#import "MPWTableView.h"

@implementation NSObject(AppKitUI)

-(void)generateAppKitUI:(MPWAppkitUIGenerator*)stream
{
    [self flattenStructureOntoStream:stream];
}

@end


@implementation MPWAppkitUIGenerator

-(SEL)streamWriterMessage
{
    return @selector(generateAppKitUI:);
}

-(void)writeTable:(MPWTable*)table
{
    MPWTableView *view = [[[MPWTableView alloc] initWithFrame: NSMakeRect(0, 0, 200, 100)] autorelease];
    [view setTable:table];
    FORWARD(view);
}

@end



@implementation MPWTable(AppKitUI)

-(void)generateAppKitUI:(MPWAppkitUIGenerator*)stream
{
    [stream writeTable:self];
}

@end



#import <MPWFoundation/DebugMacros.h>

@implementation MPWAppkitUIGenerator(testing) 



+(void)testCreateTableViewByWritingTable
{
    MPWDictArrayTable *table=[[[MPWDictArrayTable alloc] initWithObjects:@[ @{ @"first": @"Marcel"  }, @{ @"last":  @"Weiher"} ] ] autorelease];
    MPWTableView *tableview = [[self process:table] lastObject];
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
