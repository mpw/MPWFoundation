//
//  MPWTableView.m
//
//
//  Created by Marcel Weiher on 7.3.2019.
//
#import "MPWTableView.h"
#import <MPWFoundation/MPWFoundation.h>

#import <DrawingContext/MPWCGDrawingContext.h>

@interface MPWTableView()



@end

#define MPWPrivateTableViewRowDragOperationData @"MPWPrivateTableViewRowDragOperationData"


@implementation MPWTableView
{
    MPWCGDrawingContext *context;
    NSMutableArray *items;
}

objectAccessor( NSMutableArray*, items, _setItems)

-(void)setItems:(NSMutableArray*)newItems
{
    if ( self.tableColumns.count == 0 && [newItems.firstObject respondsToSelector:@selector(allKeys)]) {
        [self setKeys:[newItems.firstObject allKeys]];
    }
    [self _setItems:newItems];
}


-(void)writeObject:anObject
{
    [[self items] addObject:anObject];
}

-(void)setKeys:(NSArray*)keys
{
    for (NSString *key in keys) {
        NSTableColumn *column=[[[NSTableColumn alloc] initWithIdentifier:key] autorelease];
        column.width=150;
        [column setTitle:[key capitalizedString]];
        [self addTableColumn:column];
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


-(void)commonInit
{
    self.dataSource = self;
    self.binding = (MPWBinding*)self;
    [self setItems:[NSMutableArray array]];
    [self installProtocolNotifications];
    [self registerForDraggedTypes:[NSArray arrayWithObject:MPWPrivateTableViewRowDragOperationData]];
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


// drag operation stuff
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // Copy the row numbers to the pasteboard.
    NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    
    [pboard declareTypes:[NSArray arrayWithObject:MPWPrivateTableViewRowDragOperationData] owner:self];
    
    [pboard setData:zNSIndexSetData forType:MPWPrivateTableViewRowDragOperationData];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id )info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    // Add code here to validate the drop
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id )info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MPWPrivateTableViewRowDragOperationData];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = rowIndexes.firstIndex;
    
    [self beginUpdates];
    
    
    if (dragRow < row) {
        [self.items insertObject:[self.items objectAtIndex:dragRow] atIndex:row];
        [self.items removeObjectAtIndex:dragRow];
        
        [aTableView noteNumberOfRowsChanged];
        [aTableView moveRowAtIndex:dragRow toIndex:row-1];
        
    } else {
        id obj = [[[self.items objectAtIndex:dragRow] retain] autorelease];
        [self.items removeObjectAtIndex:dragRow];
        [self.items insertObject:obj atIndex:row];
        [aTableView noteNumberOfRowsChanged];
        [aTableView moveRowAtIndex:dragRow toIndex:row];
    }
    [self endUpdates];
    return YES;
}

//----- data source

-value {
    return self.items;
}

-(NSArray *)unorderedObjects
{
    return [self.binding value];
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
//    NSLog(@"numberOfRows: %d",(int)[[self objects] count]);
    return [[self objects] count];
}

- objectAtRow:(NSUInteger)row;
{
    if ( row >= 0 && row < [self objects].count){
        return [self objects][row];
    } else {
        return nil;
    }
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
    CGRect r = [[self context] boundingRectForText:value inPath:path];
    return r.size.height+10;
}

@end
