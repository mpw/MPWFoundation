//
//  MPWTableView.m
//
//
//  Created by Marcel Weiher on 7.3.2019.
//
#if 0
#import "MPWTableView.h"
#import <MPWFoundation/MPWFoundation.h>

#import <DrawingContext/MPWCGDrawingContext.h>

@interface MPWTableView()

@property(nonatomic,strong) MPWCGDrawingContext *context;

@end


@implementation MPWTableView




-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self commonInit];
    
    return self;
}


-(void)commonInit
{
    self.dataSource = self;
    [self installProtocolNotifications];
    self.context = [MPWCGDrawingContext currentContext];
    [self.context setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]]];
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

-(void)modelDidChange:(NSNotification *)notification
{
//    id <MPWReferencing> changedRef=[notification object];
//    if ( [self.ref  isMatchedByReference:changedRef] /* || [[self.ref asPositionsReference] isMatchedByReference:changedRef] */) {
//        [self reloadData];
//    }
}

//----- data source


-(NSArray *)unorderedObjects
{
    return self.store[self.currentReference];
}

-(NSArray *)orderObjects:(NSArray*)objects
{
    return objects;
}




-(NSArray *)filterCompletedTasks:(NSArray *)objects
{
//    if ( [self.ref.entityType isEqualToString:WLEntityTasksType]) {
//        NSMutableArray *uncompleted=[NSMutableArray array];
//        for (WLTask *task in objects) {
//            if (!task.isCompleted) {
//                [uncompleted addObject:task];
//            }
//        }
//        objects=[uncompleted copy];
//    }
//    return objects;
    return nil;
}


-(NSArray *)objects
{
    return [self filterCompletedTasks:[self orderObjects:[self unorderedObjects]]];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSLog(@"numberOfRows: %d",(int)[[self objects] count]);
    return [[self objects] count];
}

- objectAtRow:(NSUInteger)row;
{
    return [self objects][row];
}


- tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [[self objectAtRow:row] valueForKey:[tableColumn identifier]];
}

- selectedObject
{
    return [self objects][[self selectedRow]];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

-(CGFloat)calculateHeightForRow:(NSUInteger)row usingColumn:(NSString *)columnName
{
    NSString *value=[[self objectAtRow:row] valueForKey:columnName];
    id path = [self.context path:^(id<MPWDrawingContext> c) {
        [c nsrect:NSMakeRect(0, 0, [[self tableColumnWithIdentifier:columnName] width], 100000 )];
    }];
    CGRect r = [self.context boundingRectForText:value inPath:path];
    return r.size.height+10;
}

@end
#endif
