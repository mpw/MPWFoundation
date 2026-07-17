//
//  MPWTableView.m
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 26.06.26.
//
//  UIKit counterpart of the AppKit MPWTableView.  Renders an MPWTable with one
//  collection-view item per row and one presentation per MPWObjectColumn.  The
//  concrete controls are chosen by the type-to-control mapper, values are read
//  through [column objectAtIndex:] and written back through
//  [column replaceObjectAtIndex:withObject:].  UICollectionView is only the
//  rendering substrate; application code deals in MPWTable, just as with AppKit.
//

#import "MPWTableView.h"
#import "MPWUIKitUIGenerator.h"

static NSString * const MPWTableRowCellIdentifier = @"MPWTableRowCell";
static NSString * const MPWTableHeaderIdentifier  = @"MPWTableHeader";

static const CGFloat MPWTableRowHeight    = 44;
static const CGFloat MPWTableHeaderHeight  = 34;

#pragma mark - informal protocols on the model classes

// The concrete row/reorder API lives on MPWObjectArrayTable, the writeback API
// on MPWObjectColumn; both are messaged through their abstract superclass here,
// so declare the selectors to keep the compiler happy.  Reorder methods are
// additionally guarded with -respondsToSelector: at runtime.
@interface MPWTable (MPWTableRowAccess)
-(NSUInteger)count;
-(id)objectAtIndex:(NSUInteger)anIndex;
-(void)insertObject:(id)object atIndex:(NSUInteger)anIndex;
-(void)removeObjectAtIndex:(NSUInteger)anIndex;
@end

@interface MPWTableColumn (MPWTableWriteback)
-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:(id)object;
@end

// Used by the cursor selection sink, which is defined above the table view.
@interface MPWTableView (MPWSelectionSync)
- (void)synchronizeSelectionFromCursor;
@end


static void MPWConfigureColumnStack(UIStackView *stack)
{
    stack.axis         = UILayoutConstraintAxisHorizontal;
    stack.alignment    = UIStackViewAlignmentCenter;
    stack.distribution = UIStackViewDistributionFillEqually;   // equal column widths for v1
    stack.spacing      = 8;
    stack.layoutMargins = UIEdgeInsetsMake(4, 12, 4, 12);
    stack.layoutMarginsRelativeArrangement = YES;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
}

static void MPWRemoveArrangedSubviews(UIStackView *stack)
{
    for (UIView *view in [[stack.arrangedSubviews copy] autorelease]) {
        [stack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
}


#pragma mark - uniform control value access

// A single protocol every presented control understands, so the binding layer
// never has to branch on control class.  Mirrors the AppKit NSControl
// objectValue/setObjectValue: pair (value/setValue: would collide with KVC and
// with MPWReference).  Value normalisation now lives with each control type;
// this is the reusable seed for object forms/inspectors, not just the table.
@protocol MPWObjectValue <NSObject>
- (id)objectValue;
- (void)setObjectValue:(id)objectValue;
- (void)setValueEditable:(BOOL)editable;
@end

static NSString *MPWStringValue(id value)
{
    return (value == nil || value == (id)[NSNull null]) ? @"" : [value description];
}

// Defaults: a plain view has no value and ignores edits.  Subclasses below
// override the parts that apply; category dispatch picks the most specific one.
@interface UIView (MPWObjectValue) <MPWObjectValue>
@end
@implementation UIView (MPWObjectValue)
- (id)objectValue { return nil; }
- (void)setObjectValue:(id)objectValue { }
- (void)setValueEditable:(BOOL)editable { }
@end

@implementation UIControl (MPWObjectValue)
- (void)setValueEditable:(BOOL)editable { self.enabled = editable; }
@end

@implementation UILabel (MPWObjectValue)
- (id)objectValue { return self.text; }
- (void)setObjectValue:(id)objectValue { self.text = MPWStringValue(objectValue); }
@end

@implementation UITextField (MPWObjectValue)
- (id)objectValue { return self.text ?: @""; }
- (void)setObjectValue:(id)objectValue { self.text = MPWStringValue(objectValue); }
@end

@implementation UITextView (MPWObjectValue)
- (id)objectValue { return self.text ?: @""; }
- (void)setObjectValue:(id)objectValue { self.text = MPWStringValue(objectValue); }
- (void)setValueEditable:(BOOL)editable { self.editable = editable; }
@end

@implementation UISwitch (MPWObjectValue)
- (id)objectValue { return @(self.isOn); }
- (void)setObjectValue:(id)objectValue { self.on = [objectValue boolValue]; }
@end

@implementation UIDatePicker (MPWObjectValue)
- (id)objectValue { return self.date; }
- (void)setObjectValue:(id)objectValue { if ([objectValue isKindOfClass:[NSDate class]]) { self.date = objectValue; } }
@end

@implementation UISegmentedControl (MPWObjectValue)
- (id)objectValue { return @(self.selectedSegmentIndex); }
- (void)setObjectValue:(id)objectValue { self.selectedSegmentIndex = [objectValue integerValue]; }
@end

@implementation UISlider (MPWObjectValue)
- (id)objectValue { return @(self.value); }
- (void)setObjectValue:(id)objectValue { self.value = [objectValue floatValue]; }
@end

@implementation UIStepper (MPWObjectValue)
- (id)objectValue { return @(self.value); }
- (void)setObjectValue:(id)objectValue { self.value = [objectValue doubleValue]; }
@end


#pragma mark - control binding (the reusable writeback unit)

// One binding per presented column value.  It reads/writes the control through
// the MPWObjectValue protocol and performs the writeback through the column
// abstraction.  This is deliberately independent of the collection view so the
// same machinery can drive object forms/inspectors later; only -column/-row tie
// it to a table here.
@interface MPWTableControlBinding : NSObject <UITextViewDelegate>

@property (nonatomic, assign) MPWTableView *tableView;   // not retained: it owns the cell tree
@property (nonatomic, retain) MPWTableColumn *column;
@property (nonatomic, assign) NSUInteger row;

- (void)connectControl:(UIView *)control;
- (void)controlValueChanged:(id)sender;

@end


@implementation MPWTableControlBinding

- (void)connectControl:(UIView *)control
{
    if ([control isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)control;
        [field addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventEditingDidEnd];
        [field addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventEditingDidEndOnExit];
    } else if ([control isKindOfClass:[UITextView class]]) {
        [(UITextView *)control setDelegate:self];
    } else if ([control isKindOfClass:[UIControl class]]) {
        [(UIControl *)control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void)controlValueChanged:(id)sender
{
    id value = [sender objectValue];
    if (value && self.column.editable) {
        [self.column replaceObjectAtIndex:self.row withObject:value];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self controlValueChanged:textView];
}

- (void)dealloc
{
    [_column release];
    [super dealloc];
}

@end


#pragma mark - cursor selection sink

// Receives the cursor's selection notifications (via -writeObject:) and pushes
// them into the collection view.  Held by the table view; the cursor keeps only
// a weak reference back, so there is no retain cycle.
@interface MPWTableCursorSelectionSink : NSObject <Streaming>
@property (nonatomic, assign) MPWTableView *tableView;
@end

@implementation MPWTableCursorSelectionSink

- (void)writeObject:(id)anObject
{
    [self.tableView synchronizeSelectionFromCursor];
}

@end


#pragma mark - header

@interface MPWTableHeaderView : UICollectionReusableView
- (void)configureWithColumns:(NSArray<MPWTableColumn *> *)columns;
@end

@implementation MPWTableHeaderView
{
    UIStackView *_columnStack;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _columnStack = [[UIStackView alloc] init];
        MPWConfigureColumnStack(_columnStack);
        [self addSubview:_columnStack];
        [NSLayoutConstraint activateConstraints:@[
            [_columnStack.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor],
            [_columnStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_columnStack.topAnchor      constraintEqualToAnchor:self.topAnchor],
            [_columnStack.bottomAnchor   constraintEqualToAnchor:self.bottomAnchor],
        ]];
        self.backgroundColor = [UIColor systemBackgroundColor];
    }
    return self;
}

// Titles come from the capitalised column key, matching the AppKit table.
- (void)configureWithColumns:(NSArray<MPWTableColumn *> *)columns
{
    MPWRemoveArrangedSubviews(_columnStack);
    for (MPWTableColumn *column in columns) {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        label.adjustsFontForContentSizeCategory = YES;
        label.textColor = [UIColor secondaryLabelColor];
        NSString *title = column.title ?: column.key ?: @"";
        label.text = [title capitalizedString];
        [_columnStack addArrangedSubview:label];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    MPWRemoveArrangedSubviews(_columnStack);
}

- (void)dealloc
{
    [_columnStack release];
    [super dealloc];
}

@end


#pragma mark - row cell

@interface MPWTableRowCell ()
@property (nonatomic, retain) UIStackView *columnStack;
@property (nonatomic, retain) UIView *separator;
@property (nonatomic, retain) NSMutableArray<MPWTableControlBinding *> *bindings;
@end

@implementation MPWTableRowCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _bindings = [[NSMutableArray alloc] init];

        _columnStack = [[UIStackView alloc] init];
        MPWConfigureColumnStack(_columnStack);
        [self.contentView addSubview:_columnStack];

        _separator = [[UIView alloc] init];
        _separator.backgroundColor = [UIColor separatorColor];
        _separator.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_separator];

        [NSLayoutConstraint activateConstraints:@[
            [_columnStack.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_columnStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_columnStack.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor],
            [_columnStack.bottomAnchor   constraintEqualToAnchor:_separator.topAnchor],
            [_separator.leadingAnchor    constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_separator.trailingAnchor   constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_separator.bottomAnchor     constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_separator.heightAnchor     constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale],
        ]];

        UIView *selectedBackground = [[[UIView alloc] init] autorelease];
        selectedBackground.backgroundColor = [UIColor systemGray5Color];
        self.selectedBackgroundView = selectedBackground;
    }
    return self;
}

- (NSArray<UIView *> *)presentations
{
    return self.columnStack.arrangedSubviews;
}

- (void)configureWithColumns:(NSArray<MPWTableColumn *> *)columns
                         row:(NSUInteger)row
                  typeMapper:(MPWTypeToObjectMapper *)typeMapper
                   tableView:(MPWTableView *)tableView
{
    MPWRemoveArrangedSubviews(self.columnStack);
    [self.bindings removeAllObjects];
    for (MPWTableColumn *column in columns) {
        UIView *presentation = [self presentationForColumn:column
                                                       row:row
                                                typeMapper:typeMapper
                                                 tableView:tableView];
        [self.columnStack addArrangedSubview:presentation];
    }
}

- (UIView *)presentationForColumn:(MPWTableColumn *)column
                              row:(NSUInteger)row
                       typeMapper:(MPWTypeToObjectMapper *)typeMapper
                        tableView:(MPWTableView *)tableView
{
    id value = [column objectAtIndex:row];        // read through the column abstraction

    UIView *presentation = column.type ? [typeMapper atType:column.type] : nil;
    if (!presentation) {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.numberOfLines = 1;
        label.adjustsFontForContentSizeCategory = YES;
        presentation = label;
    }
    presentation.translatesAutoresizingMaskIntoConstraints = NO;

    MPWTableControlBinding *binding = [[[MPWTableControlBinding alloc] init] autorelease];
    binding.tableView = tableView;
    binding.column    = column;
    binding.row       = row;
    [presentation setObjectValue:value];
    [presentation setValueEditable:column.editable];
    if (column.editable) {
        [binding connectControl:presentation];
    }
    [self.bindings addObject:binding];            // keeps the binding alive for the cell's lifetime
    return presentation;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    MPWRemoveArrangedSubviews(self.columnStack);
    [self.bindings removeAllObjects];
}

- (void)dealloc
{
    [_columnStack release];
    [_separator release];
    [_bindings release];
    [super dealloc];
}

@end


#pragma mark - table view

@interface MPWTableView ()
@property (nonatomic, retain) MPWTable *table;
@property (nonatomic, retain) NSArray<MPWTableColumn *> *tableColumns;
@property (nonatomic, retain) MPWTypeToObjectMapper *type2Control;
@property (nonatomic, retain) MPWTableCursorSelectionSink *cursorSelectionSink;
@property (nonatomic, retain) UILongPressGestureRecognizer *reorderGesture;
@end

@implementation MPWTableView
{
    BOOL _didCommonInit;
    BOOL _synchronizingSelection;   // guards against selection<->cursor feedback loops
}

@synthesize cursor = _cursor;

+ (UICollectionViewLayout *)defaultTableLayout
{
    UICollectionViewFlowLayout *layout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
    layout.scrollDirection        = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing     = 0;
    layout.minimumInteritemSpacing = 0;
    layout.headerReferenceSize    = CGSizeMake(1, MPWTableHeaderHeight);
    return layout;
}

// UICollectionView requires a layout at init time; provide one so the plain
// -initWithFrame: path (used by the AppKit-style call sites) works.
- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame collectionViewLayout:[[self class] defaultTableLayout]];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) { [self commonInit]; }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) { [self commonInit]; }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

// Replicates the intent of the AppKit -commonInit; runs exactly once regardless
// of which initializer / nib path was taken.
- (void)commonInit
{
    if (_didCommonInit) { return; }
    _didCommonInit = YES;

    [self installProtocolNotifications];
    self.dataSource = self;
    self.delegate   = self;
    self.allowsSelection = YES;
    self.allowsMultipleSelection = NO;
    self.backgroundColor = [UIColor systemBackgroundColor];
    self.alwaysBounceVertical = YES;

    [self registerClass:[MPWTableRowCell class] forCellWithReuseIdentifier:MPWTableRowCellIdentifier];
    [self registerClass:[MPWTableHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:MPWTableHeaderIdentifier];

    self.type2Control = [MPWUIKitUIGenerator defaultTypes2UIMapper];

    self.cursorSelectionSink = [[[MPWTableCursorSelectionSink alloc] init] autorelease];
    self.cursorSelectionSink.tableView = self;

    // A plain UICollectionView (unlike UICollectionViewController) installs no
    // standard reordering gesture, so we drive interactive movement ourselves.
    self.reorderGesture = [[[UILongPressGestureRecognizer alloc]
                            initWithTarget:self action:@selector(handleReorderGesture:)] autorelease];
    [self addGestureRecognizer:self.reorderGesture];
}

#pragma mark table

- (NSUInteger)rowCount
{
    return [self.table respondsToSelector:@selector(count)] ? [self.table count] : 0;
}

- (void)setTable:(MPWTable *)newTable
{
    if (_table != newTable) {
        [_table release];
        _table = [newTable retain];
    }
    self.tableColumns = [newTable columns] ?: @[];
    [self reloadData];
    [self synchronizeSelectionFromCursor];
}

- (id)value   { return self.table; }        // MPWReferencing-ish, mirrors AppKit

- (id)objectAtRow:(NSUInteger)row
{
    if (row < [self rowCount] && [self.table respondsToSelector:@selector(objectAtIndex:)]) {
        return [self.table objectAtIndex:row];
    }
    return nil;
}

- (id)selectedObject
{
    NSIndexPath *selection = self.indexPathsForSelectedItems.firstObject;
    return selection ? [self objectAtRow:selection.item] : nil;
}

#pragma mark cursor / selection

- (void)setCursor:(MPWArrayCursor *)newCursor
{
    if (_cursor == newCursor) { return; }
    if (_cursor.selectionChanges == self.cursorSelectionSink) {
        _cursor.selectionChanges = nil;
    }
    [_cursor release];
    _cursor = [newCursor retain];
    _cursor.selectionChanges = self.cursorSelectionSink;
    [self synchronizeSelectionFromCursor];
}

// External cursor change -> select and reveal the row.  Programmatic selection
// does not fire -didSelectItemAtIndexPath:, and the guard flag covers the case
// where we are already inside a user-driven update.
- (void)synchronizeSelectionFromCursor
{
    if (_synchronizingSelection || !self.cursor) { return; }
    _synchronizingSelection = YES;

    NSInteger row = self.cursor.offset;
    for (NSIndexPath *selected in self.indexPathsForSelectedItems) {
        if (selected.item != row) {
            [self deselectItemAtIndexPath:selected animated:NO];
        }
    }
    if (row >= 0 && (NSUInteger)row < [self rowCount]) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:row inSection:0];
        [self selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        if (self.window) {   // scrolling offscreen without a window can assert in tests
            [self scrollToItemAtIndexPath:path
                         atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                 animated:NO];
        }
    }
    _synchronizingSelection = NO;
}

// User selection -> push into the cursor (guarded so the resulting cursor
// notification does not bounce back into a selection update).
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.cursor && !_synchronizingSelection && self.cursor.offset != (long)indexPath.item) {
        _synchronizingSelection = YES;
        self.cursor.offset = indexPath.item;
        _synchronizingSelection = NO;
    }
}

- (void)selectionDidChange:(NSNotification *)notification
{
    [self synchronizeSelectionFromCursor];
}

- (void)modelDidChange:(NSNotification *)notification
{
    self.tableColumns = [self.table columns] ?: @[];
    [self reloadData];
    [self synchronizeSelectionFromCursor];
}

#pragma mark data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self rowCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MPWTableRowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MPWTableRowCellIdentifier
                                                                     forIndexPath:indexPath];
    [cell configureWithColumns:self.tableColumns
                           row:indexPath.item
                    typeMapper:self.type2Control
                     tableView:self];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    MPWTableHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                   withReuseIdentifier:MPWTableHeaderIdentifier
                                                                          forIndexPath:indexPath];
    [header configureWithColumns:self.tableColumns];
    return header;
}

#pragma mark layout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(MAX(0, CGRectGetWidth(collectionView.bounds)), MPWTableRowHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
 referenceSizeForHeaderInSection:(NSInteger)section
{
    return self.tableColumns.count
        ? CGSizeMake(CGRectGetWidth(collectionView.bounds), MPWTableHeaderHeight)
        : CGSizeZero;
}

#pragma mark reordering

- (BOOL)canReorderTable
{
    return [self.table respondsToSelector:@selector(insertObject:atIndex:)]
        && [self.table respondsToSelector:@selector(removeObjectAtIndex:)];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self canReorderTable];
}

// Mutate the underlying table so its order matches the visual move: remove from
// the source index, then insert at the destination index (already expressed in
// the post-move coordinate space, matching UICollectionView semantics).
- (void)collectionView:(UICollectionView *)collectionView
   moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
           toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (![self canReorderTable] || sourceIndexPath.item == destinationIndexPath.item) { return; }

    id object = [[[self objectAtRow:sourceIndexPath.item] retain] autorelease];
    [self.table removeObjectAtIndex:sourceIndexPath.item];
    [self.table insertObject:object atIndex:destinationIndexPath.item];

    if (self.cursor) { self.cursor.offset = destinationIndexPath.item; }
}

- (void)handleReorderGesture:(UILongPressGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *path = [self indexPathForItemAtPoint:location];
            if (path && [self collectionView:self canMoveItemAtIndexPath:path]) {
                [self beginInteractiveMovementForItemAtIndexPath:path];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
            [self updateInteractiveMovementTargetPosition:location];
            break;
        case UIGestureRecognizerStateEnded:
            [self endInteractiveMovement];
            break;
        default:
            [self cancelInteractiveMovement];
            break;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_cursor.selectionChanges == self.cursorSelectionSink) {
        _cursor.selectionChanges = nil;
    }
    _cursorSelectionSink.tableView = nil;
    [_binding release];
    [_cursor release];
    [_valueFilter release];
    [_table release];
    [_tableColumns release];
    [_type2Control release];
    [_cursorSelectionSink release];
    [_reorderGesture release];
    [super dealloc];
}

@end


#pragma mark - tests

#import <MPWFoundation/DebugMacros.h>

// Spy column: counts reads/writes and routes them through the column API so the
// tests can prove values move via [column objectAtIndex:] /
// [column replaceObjectAtIndex:withObject:] and nowhere else.
@interface MPWTableViewTestColumn : MPWTableColumn
@property (nonatomic, retain) NSMutableArray *values;
@property (nonatomic, assign) NSUInteger readCount;
@property (nonatomic, assign) NSUInteger writeCount;
@end

@implementation MPWTableViewTestColumn

- (id)objectAtIndex:(NSUInteger)index
{
    self.readCount++;
    return self.values[index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
    self.writeCount++;
    [self.values replaceObjectAtIndex:index withObject:object];
}

- (void)dealloc { [_values release]; [super dealloc]; }

@end


// Spy table implementing the row/reorder API that the abstract MPWTable leaves
// to its concrete subclasses.
@interface MPWTableViewTestTable : MPWTable
@property (nonatomic, retain) NSMutableArray *rows;
@end

@implementation MPWTableViewTestTable

- (NSUInteger)count { return self.rows.count; }
- (id)objectAtIndex:(NSUInteger)index { return self.rows[index]; }
- (void)insertObject:(id)object atIndex:(NSUInteger)index { [self.rows insertObject:object atIndex:index]; }
- (void)removeObjectAtIndex:(NSUInteger)index { [self.rows removeObjectAtIndex:index]; }
- (void)dealloc { [_rows release]; [super dealloc]; }

@end


@interface MPWReloadCountingTableView : MPWTableView
@property (nonatomic, assign) NSUInteger reloadCount;
@end

@implementation MPWReloadCountingTableView
- (void)reloadData { self.reloadCount++; [super reloadData]; }
@end


@implementation MPWTableView (testing)

+ (MPWTableViewTestTable *)testTable
{
    MPWTableViewTestColumn *name = [[[MPWTableViewTestColumn alloc] init] autorelease];
    name.key      = @"name";
    name.type     = [MPWTypeStore store][@"id"];
    name.editable = YES;
    name.values   = [NSMutableArray arrayWithObjects:@"Ada", @"Grace", nil];

    MPWTableViewTestColumn *active = [[[MPWTableViewTestColumn alloc] init] autorelease];
    active.key      = @"active";
    active.type     = [MPWTypeStore store][@"bool"];
    active.editable = YES;
    active.values   = [NSMutableArray arrayWithObjects:@YES, @NO, nil];

    MPWTableViewTestTable *table = [[[MPWTableViewTestTable alloc] init] autorelease];
    table.rows    = [NSMutableArray arrayWithObjects:@"row0", @"row1", nil];
    table.columns = @[name, active];
    return table;
}

+ (MPWTableView *)testViewWithTable:(MPWTableViewTestTable *)table
{
    MPWTableView *view = [[[MPWTableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
    [view setTable:table];
    return view;
}

+ (MPWTableRowCell *)configuredCellForTable:(MPWTableViewTestTable *)table row:(NSUInteger)row
{
    MPWTableRowCell *cell = [[[MPWTableRowCell alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
    [cell configureWithColumns:table.columns
                           row:row
                    typeMapper:[MPWUIKitUIGenerator defaultTypes2UIMapper]
                     tableView:nil];
    return cell;
}

// 1. Setting a table yields the correct number of rows.
+ (void)testSettingTableProvidesRows
{
    MPWTableView *view = [self testViewWithTable:[self testTable]];
    INTEXPECT([view collectionView:view numberOfItemsInSection:0], 2, @"one item per table row");
}

// 2 & 3. One presentation per column, and values are read through the columns.
+ (void)testRowCreatesOnePresentationPerColumnAndReadsColumns
{
    MPWTableViewTestTable *table = [self testTable];
    MPWTableRowCell *cell = [self configuredCellForTable:table row:0];
    INTEXPECT(cell.presentations.count, 2, @"one presentation per column");
    INTEXPECT([(MPWTableViewTestColumn *)table.columns[0] readCount], 1, @"value read through first column");
    INTEXPECT([(MPWTableViewTestColumn *)table.columns[1] readCount], 1, @"value read through second column");
}

// 4. Editing writes back through replaceObjectAtIndex:withObject:.
//    The control is wired to a binding via target/action; we assert that wiring
//    and then invoke the registered action directly.  (sendActionsForControlEvents:
//    routes through [UIApplication sharedApplication], which is absent in a
//    headless test process, so invoking the target-action pair is the reliable
//    way to exercise the real writeback path.)
+ (void)testEditingWritesThroughColumn
{
    MPWTableViewTestTable *table = [self testTable];
    MPWTableRowCell *cell = [self configuredCellForTable:table row:0];
    UITextField *field = (id)cell.presentations[0];
    EXPECTTRUE([field isKindOfClass:[UITextField class]], @"id column presents a text field");

    id binding = [field allTargets].anyObject;
    EXPECTNOTNIL(binding, @"editable control is wired to a binding target");
    NSArray *actions = [field actionsForTarget:binding forControlEvent:UIControlEventEditingDidEnd];
    EXPECTTRUE(actions.count > 0, @"binding is connected for the end-of-edit event");

    field.text = @"Katherine";
    [binding performSelector:@selector(controlValueChanged:) withObject:field];

    MPWTableViewTestColumn *column = (id)table.columns[0];
    INTEXPECT(column.writeCount, 1, @"write sent through column");
    IDEXPECT(column.values[0], @"Katherine", @"column received the edited value");
}

// 5. objectAtRow: returns the model object and is safe for invalid rows.
+ (void)testObjectAtRowIsSafe
{
    MPWTableView *view = [self testViewWithTable:[self testTable]];
    IDEXPECT([view objectAtRow:1], @"row1", @"object at valid row");
    EXPECTNIL([view objectAtRow:2], @"invalid row returns nil");
    EXPECTNIL([view objectAtRow:9999], @"far invalid row returns nil");
}

// 6. selectedObject reflects collection selection and is safe with no selection.
+ (void)testSelectedObjectReflectsSelection
{
    MPWTableView *view = [self testViewWithTable:[self testTable]];
    EXPECTNIL([view selectedObject], @"no selection returns nil");
    [view selectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]
                       animated:NO
                 scrollPosition:UICollectionViewScrollPositionNone];
    IDEXPECT([view selectedObject], @"row1", @"selected object follows collection selection");
}

// 7. User selection updates cursor.offset.
+ (void)testSelectingRowUpdatesCursor
{
    MPWTableViewTestTable *table = [self testTable];
    MPWTableView *view = [self testViewWithTable:table];
    MPWArrayCursor *cursor = [[[MPWArrayCursor alloc] initWithArray:table.rows] autorelease];
    view.cursor = cursor;
    [view collectionView:view didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    INTEXPECT(cursor.offset, 1, @"user selection updates the cursor");
}

// 8. External cursor change selects the row without recursion / feedback loop.
+ (void)testCursorChangeSelectsRow
{
    MPWTableViewTestTable *table = [self testTable];
    MPWTableView *view = [self testViewWithTable:table];
    MPWArrayCursor *cursor = [[[MPWArrayCursor alloc] initWithArray:table.rows] autorelease];
    view.cursor = cursor;
    cursor.offset = 1;
    INTEXPECT(view.indexPathsForSelectedItems.firstObject.item, 1, @"external cursor change selects the row");
    cursor.offset = 0;
    INTEXPECT(view.indexPathsForSelectedItems.firstObject.item, 0, @"selection tracks the cursor both ways");
}

// 9. modelDidChange: refreshes the displayed data.
+ (void)testModelChangeReloadsData
{
    MPWReloadCountingTableView *view = [[[MPWReloadCountingTableView alloc]
                                         initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
    [view setTable:[self testTable]];
    NSUInteger before = view.reloadCount;
    [view modelDidChange:nil];
    INTEXPECT(view.reloadCount, before + 1, @"model change reloads the collection");
}

// 10. Reordering mutates the underlying table in visual order.
+ (void)testReorderingMutatesTable
{
    MPWTableViewTestTable *table = [self testTable];
    MPWTableView *view = [self testViewWithTable:table];
    [view collectionView:view
     moveItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
             toIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    IDEXPECT(table.rows[0], @"row1", @"first row moved away");
    IDEXPECT(table.rows[1], @"row0", @"moved row inserted at the destination");
}

+ (NSArray *)testSelectors
{
    return @[
        @"testSettingTableProvidesRows",
        @"testRowCreatesOnePresentationPerColumnAndReadsColumns",
        @"testEditingWritesThroughColumn",
        @"testObjectAtRowIsSafe",
        @"testSelectedObjectReflectsSelection",
        @"testSelectingRowUpdatesCursor",
        @"testCursorChangeSelectsRow",
        @"testModelChangeReloadsData",
        @"testReorderingMutatesTable",
    ];
}

@end
