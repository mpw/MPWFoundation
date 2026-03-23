//
//  MPWTableView.m
//
//
//  Created by Marcel Weiher on 7.3.2019.
//
#import "MPWTableView.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWTableViewColumn.h"

#import <DrawingContext/MPWCGDrawingContext.h>

@interface MPWTableView()


@end

#define MPWPrivateTableViewRowDragOperationData @"MPWPrivateTableViewRowDragOperationData"


@implementation MPWTableView
{
    MPWCGDrawingContext *context;
    MPWDictArrayTable *table;
}

objectAccessor( MPWDictArrayTable*, table, _setTable)

-(void)setTable:(MPWDictArrayTable*)newItems
{
    NSArray *tableColumns = [newItems computedColumns];
    [self removeCurrentColumns];
    for ( MPWDictColumn *tableColumn in tableColumns ) {
        NSString *key = [tableColumn key];
        MPWTableViewColumn *c=[[[MPWTableViewColumn alloc] initWithIdentifier:key] autorelease];
        c.tableColumn = tableColumn;
        c.width=150;
        [c setTitle:[key capitalizedString]];
        [self addTableColumn:c];
    }
    [self _setTable:newItems];
}

-(void)setDicts:dictArray
{
    [self setTable:[[[MPWDictArrayTable alloc] initWithObjects:dictArray] autorelease]];
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

//-(void)setKeys:(NSArray*)keys target:aTarget
//{
//    [self removeCurrentColumns];
//    for (NSString *key in keys) {
//        MPWTableViewColumn *column=[[[MPWTableViewColumn alloc] initWithIdentifier:key] autorelease];
//        column.binding = [MPWPropertyBinding valueForName:key];
//        [column.binding bindToTarget:aTarget];
//        column.width=150;
//        [column setTitle:[key capitalizedString]];
//        [self addTableColumn:column];
//    }
//}

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
    self.dataSource = self;
    self.binding = (MPWReference*)self;
    [self setDicts:[NSMutableArray array]];
    [self installProtocolNotifications];
    self.delegate = self;
    [self registerForDraggedTypes:[NSArray arrayWithObject:MPWPrivateTableViewRowDragOperationData]];
    self.dataSource = self;
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

-(NSArray *)unorderedObjects
{
    id newItems = [self.binding value];
    if ( self.valueFilter) {
        newItems = self.valueFilter( newItems );
    }
    return newItems;
}

-(NSArray *)orderObjects:(NSArray*)objects
{
    return objects;
}

-(NSArray *)objects
{
    return [self orderObjects:[self unorderedObjects]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSLog(@"numberOfRows: %@ %d",self,(int)[[self objects] count]);
    return [[self objects] count];
}

- objectAtRow:(NSUInteger)row;
{
    if ( row >= 0 && row < [self objects].count){
        return [[self objects] objectAtIndex:row];
    } else {
        return nil;
    }
}

- tableView:(NSTableView *)tableView objectValueForTableColumn:(MPWTableViewColumn *)tableColumn row:(NSInteger)row
{
    if (  [tableColumn respondsToSelector:@selector(tableColumn)]) {
        return [[tableColumn tableColumn] objectAtIndex:row];
    } else {
        return nil;
    }
}

- selectedObject
{
    return [self objects][[self selectedRow]];
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
    if ( [self.mpwDelegate respondsToSelector:@selector(tableViewSelectionDidChange:)] && self.mpwDelegate != self) {
        [self.mpwDelegate tableViewSelectionDidChange:notification];
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
