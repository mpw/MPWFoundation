//
//  MPWTableView.m
//
//
//  Created by Marcel Weiher on 7.3.2019.
//
#import "MPWTableView.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWTableViewColumn.h"
#import "MPWAppkitUIGenerator.h"

#import <DrawingContext/MPWCGDrawingContext.h>

@interface MPWTableView()

@property (nonatomic,strong) MPWTypeToObjectMapper *type2Control;

@end

#define MPWPrivateTableViewRowDragOperationData @"MPWPrivateTableViewRowDragOperationData"


@implementation MPWTableView
{
    MPWCGDrawingContext *context;
    MPWDictArrayTable *table;
}

objectAccessor( MPWDictArrayTable*, table, _setTable)

-(void)setTable:(MPWTable*)newItems
{
    NSArray *columns = [newItems columns];
    [self removeCurrentColumns];
    double width = self.frame.size.width-40;
    width = MAX( 400, width);
    double perColumn = width / columns.count;
    for ( MPWObjectColumn *column in columns ) {
        NSString *key = [column key];
        MPWTableViewColumn *c=[[[MPWTableViewColumn alloc] initWithIdentifier:key] autorelease];
        c.tableColumn = column;
        c.width=perColumn;
        c.editable = column.editable;
        [c setTitle:[key capitalizedString]];
        [self addTableColumn:c];
    }
    [self _setTable:newItems];
}

- (NSView *) tableView:(MPWTableView *) tableView
    viewForTableColumn:(MPWTableViewColumn *) tableColumn
                   row:(NSInteger) row
{
    NSControl *control=[self.type2Control atType:tableColumn.tableColumn.type];
    control.frame = NSMakeRect(0, 0, tableColumn.width, 20);
    control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    control.target = tableView;
    control.action = @selector(tableTextFieldChanged:);
    return control;
}

- (void)tableTextFieldChanged:(NSTextField *)sender
{
    NSInteger row = [self rowForView:sender];
    NSInteger column = [self columnForView:sender];
    
    if (row >= 0 && column >= 0) {
        MPWTableViewColumn* tableColumn = [self tableColumns][column];
        [self tableView:self setObjectValue:sender.objectValue forTableColumn:tableColumn row:row];
        [self modelDidChange:nil];
    }
}

-(NSView*)rowViewAtRow:(NSInteger) row
       makeIfNecessary:(BOOL) makeIfNecessary
{
    NSView *rowView = [super rowViewAtRow:row makeIfNecessary:makeIfNecessary];
//    NSLog(@"rowView[%ld]=%@",(long)row,[rowView class]);
    return rowView;
}


- (NSView *) viewAtColumn:(NSInteger) column
                      row:(NSInteger) row
          makeIfNecessary:(BOOL) makeIfNecessary
{
    NSView *cellView = [super viewAtColumn:column row:row makeIfNecessary:makeIfNecessary];
//    NSLog(@"cellView[%ld][%ld]=%@",(long)row,(long)column,[cellView class]);
    return cellView;
}

-(void)setDicts:dictArray
{
    [self setTable:[[[MPWDictArrayTable alloc] initWithObjects:dictArray] autorelease]];
}

-(void)setObjects:objectArray
{
    [self setTable:[[[MPWObjectArrayTable alloc] initWithObjects:objectArray] autorelease]];
}

-(void)writeObject:anObject
{
    [(NSMutableArray*)[self objects] addObject:anObject];
}

-(void)removeCurrentColumns
{
    while ( self.tableColumns.count ) {
        [self removeTableColumn:self.tableColumns.firstObject];
    }
}


-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self commonInit];
    return self;
}

-(MPWCGDrawingContext*)createContext
{
    if ( [NSGraphicsContext currentContext] ) {
        MPWCGDrawingContext *aContext=[MPWCGDrawingContext currentContext];
        [aContext setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]]];
        return aContext;
    }
    return nil;
}

lazyAccessor(MPWCGDrawingContext*, context, setContext, createContext )

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(MPWTableViewColumn *)tableColumn row:(NSInteger)row
{
    [tableColumn.tableColumn replaceObjectAtIndex:row withObject:object];
}

-(void)commonInit
{
    self.binding = (MPWReference*)self;
    [self installProtocolNotifications];
    self.delegate = self;
    [self registerForDraggedTypes:[NSArray arrayWithObject:MPWPrivateTableViewRowDragOperationData]];
    NSRect savedFrameBecauseSettingDataSourceResetsFrame = self.frame;
    self.dataSource = self;
    self.frame = savedFrameBecauseSettingDataSourceResetsFrame;
    self.type2Control = [MPWAppkitUIGenerator defaultTypes2UIMapper];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

-(void)modelDidChange:(NSNotification *)notification
{
        [self reloadData];
}

//----- data source

-value {
    return self.table;
}

-(NSArray *)objects
{
    return self.table;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.table count];
}

- objectAtRow:(NSUInteger)row;
{
    if ( row >= 0 && row < self.table.count){
        return [self.table objectAtIndex:row];
    } else {
        return nil;
    }
}

- tableView:(NSTableView *)tableView objectValueForTableColumn:(MPWTableViewColumn *)tableColumn row:(NSInteger)row
{
    if (  [tableColumn respondsToSelector:@selector(tableColumn)] && row < self.table.count ) {
        return [[tableColumn tableColumn] objectAtIndex:row];
    } else {
        return nil;
    }
}

- selectedObject
{
    return [self.table objectAtIndex:self.selectedRow];
}

-(void)selectionDidChange:something
{
    if ( self.cursor && self.cursor.offset != [self selectedRow]) {
        [self selectRow:self.cursor.offset byExtendingSelection:NO];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.cursor ) {
        self.cursor.offset = [self selectedRow];
    }
    if (  self.mpwDelegate != self) {
        if ( [self.mpwDelegate respondsToSelector:@selector(tableViewSelectionDidChange:)] ) {
            [self.mpwDelegate tableViewSelectionDidChange:notification.userInfo];
        } else if ( [self.mpwDelegate respondsToSelector:@selector(didSelect:)] ) {
            [self.mpwDelegate didSelect: self.selectedObject];
        }
    }
}


-(CGFloat)calculateHeightForRow:(NSUInteger)row usingColumn:(NSString *)columnName
{
    NSString *value=[[self objectAtRow:row] valueForKey:columnName];
    id path = [self.context path:^(id<MPWDrawingContext> c) {
        [c nsrect:NSMakeRect(0, 0, [[self tableColumnWithIdentifier:columnName] width], 100000 )];
    }];
    CGRect r = [[self context] boundingRectForText:value inPath:path];
    return r.size.height+12;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:MPWPrivateTableViewRowDragOperationData] owner:self];
    [pboard setData:zNSIndexSetData forType:MPWPrivateTableViewRowDragOperationData];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id )info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id )info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MPWPrivateTableViewRowDragOperationData];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = rowIndexes.firstIndex;
    
    [self beginUpdates];
    if (dragRow < row) {
        [self.table insertObject:[self.table objectAtIndex:dragRow] atIndex:row];
        [self.table removeObjectAtIndex:dragRow];
        
        [aTableView noteNumberOfRowsChanged];
        [aTableView moveRowAtIndex:dragRow toIndex:row-1];
        
    } else {
        id obj = [[[self.table objectAtIndex:dragRow] retain] autorelease];
        [self.table removeObjectAtIndex:dragRow];
        [self.table insertObject:obj atIndex:row];
        [aTableView noteNumberOfRowsChanged];
        [aTableView moveRowAtIndex:dragRow toIndex:row];
    }
    [self endUpdates];
    return YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end


@implementation MPWGenericIdentifier(allKeys)

-(NSArray*)allKeys
{
    return @[@"path"];
}

@end
@implementation NSObject(allKeys)

-(NSArray*)allKeys
{
    return @[@"self"];
}

@end

