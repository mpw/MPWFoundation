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
static NSString * const MPWTableFooterIdentifier  = @"MPWTableFooter";

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
@property (nonatomic, retain) id rowObject;
@property (nonatomic, copy) NSDictionary *metadata;

- (void)connectControl:(UIView *)control;
- (void)controlValueChanged:(id)sender;

@end


@implementation MPWTableControlBinding

- (void)connectControl:(UIView *)control
{
    BOOL buttonUsesMenu = NO;
    if ([control isKindOfClass:[UIButton class]]) {
        if (@available(iOS 14.0, *)) {
            buttonUsesMenu = [(UIButton *)control showsMenuAsPrimaryAction];
        }
    }
    if ([control isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)control;
        [field addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventEditingDidEnd];
        [field addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventEditingDidEndOnExit];
    } else if ([control isKindOfClass:[UITextView class]]) {
        [(UITextView *)control setDelegate:self];
    } else if ([control isKindOfClass:[UIButton class]] && !buttonUsesMenu) {
        [(UIButton *)control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventTouchUpInside];
    } else if ([control isKindOfClass:[UIControl class]]) {
        [(UIControl *)control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void)controlValueChanged:(id)sender
{
    id value = [sender objectValue];
    if (self.metadata[MPWPresentationActionKey]) {
        if (self.tableView.activationHandler) {
            self.tableView.activationHandler(self.rowObject, self.metadata);
        }
    } else if (value && [self.column isEditableAtIndex:self.row]) {
        [self.column replaceObjectAtIndex:self.row withObject:value];
        if (self.tableView.valueChangeHandler) {
            self.tableView.valueChangeHandler(self.rowObject, value, self.metadata);
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self controlValueChanged:textView];
}

- (void)dealloc
{
    [_column release];
    [_rowObject release];
    [_metadata release];
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
- (void)configureWithText:(nullable NSString*)text footer:(BOOL)isFooter;
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

- (void)configureWithText:(NSString*)text footer:(BOOL)isFooter
{
    MPWRemoveArrangedSubviews(_columnStack);
    UILabel *label=[[[UILabel alloc] init] autorelease];
    label.font=[UIFont preferredFontForTextStyle:isFooter ? UIFontTextStyleFootnote : UIFontTextStyleCaption1];
    label.adjustsFontForContentSizeCategory=YES;
    label.textColor=[UIColor secondaryLabelColor];
    label.numberOfLines=isFooter ? 0 : 1;
    label.text=text;
    [_columnStack addArrangedSubview:label];
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
- (void)configureWithColumns:(NSArray<MPWTableColumn*>*)columns
                         row:(NSUInteger)row
                   rowObject:(id)rowObject
                  typeMapper:(MPWTypeToObjectMapper*)typeMapper
                   tableView:(MPWTableView*)tableView;
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
    [self configureWithColumns:columns row:row rowObject:nil typeMapper:typeMapper tableView:tableView];
}

- (void)configureWithColumns:(NSArray<MPWTableColumn *> *)columns
                         row:(NSUInteger)row
                   rowObject:(id)rowObject
                  typeMapper:(MPWTypeToObjectMapper *)typeMapper
                   tableView:(MPWTableView *)tableView
{
    MPWRemoveArrangedSubviews(self.columnStack);
    [self.bindings removeAllObjects];
    MPWTableColumn *spanningColumn=nil;
    for (MPWTableColumn *column in columns) {
        if ([[column presentationMetadataAtIndex:row][@"spansColumns"] boolValue]) {
            spanningColumn=column;
            break;
        }
    }
    if (spanningColumn) { columns=@[spanningColumn]; }
    for (MPWTableColumn *column in columns) {
        UIView *presentation = [self presentationForColumn:column
                                                       row:row
                                                 rowObject:rowObject
                                                typeMapper:typeMapper
                                                 tableView:tableView];
        [self.columnStack addArrangedSubview:presentation];
    }
}

- (UIView *)presentationForColumn:(MPWTableColumn *)column
                              row:(NSUInteger)row
                        rowObject:(id)rowObject
                       typeMapper:(MPWTypeToObjectMapper *)typeMapper
                        tableView:(MPWTableView *)tableView
{
    id value = [column objectAtIndex:row];        // read through the column abstraction

    NSDictionary *metadata=[column presentationMetadataAtIndex:row];
    MPWTypeDefinition *type=[column typeAtIndex:row];
    UIView *presentation=[MPWUIKitUIGenerator controlForType:type presentationMetadata:metadata typeMapper:typeMapper];
    presentation.translatesAutoresizingMaskIntoConstraints = NO;

    MPWTableControlBinding *binding = [[[MPWTableControlBinding alloc] init] autorelease];
    binding.tableView = tableView;
    binding.column    = column;
    binding.row       = row;
    binding.rowObject = rowObject;
    binding.metadata  = metadata;
    [presentation setObjectValue:value];
    BOOL editable=[column isEditableAtIndex:row];
    [presentation setValueEditable:editable || metadata[MPWPresentationActionKey] != nil];
    if (editable || metadata[MPWPresentationActionKey]) {
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
- (MPWTable*)componentTableAtSection:(NSUInteger)section;
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
    self.presentationStyle = MPWTablePresentationStyleAutomatic;

    [self registerClass:[MPWTableRowCell class] forCellWithReuseIdentifier:MPWTableRowCellIdentifier];
    [self registerClass:[MPWTableHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:MPWTableHeaderIdentifier];
    [self registerClass:[MPWTableHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:MPWTableFooterIdentifier];

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

- (MPWTable*)componentTableAtSection:(NSUInteger)section
{
    return [self.table componentTableAtIndex:section];
}

- (BOOL)usesFormPresentation
{
    if (self.presentationStyle == MPWTablePresentationStyleForm) { return YES; }
    if (self.presentationStyle == MPWTablePresentationStyleTabular) { return NO; }
    return [self.table.presentationMetadata[MPWPresentationStyleKey] isEqual:@"form"];
}

- (NSUInteger)globalRowForIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger row=indexPath.item;
    for (NSUInteger section=0; section<indexPath.section; section++) {
        row += [self componentTableAtSection:section].count;
    }
    return row;
}

- (NSIndexPath*)indexPathForGlobalRow:(NSUInteger)row
{
    for (NSUInteger section=0; section<self.table.componentTables.count; section++) {
        NSUInteger count=[self componentTableAtSection:section].count;
        if (row < count) { return [NSIndexPath indexPathForItem:row inSection:section]; }
        row -= count;
    }
    return nil;
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
    return selection ? [[self componentTableAtSection:selection.section] objectAtIndex:selection.item] : nil;
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
        if ([self globalRowForIndexPath:selected] != row) {
            [self deselectItemAtIndexPath:selected animated:NO];
        }
    }
    if (row >= 0 && (NSUInteger)row < [self rowCount]) {
        NSIndexPath *path = [self indexPathForGlobalRow:row];
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
    NSUInteger globalRow=[self globalRowForIndexPath:indexPath];
    if (self.cursor && !_synchronizingSelection && self.cursor.offset != (long)globalRow) {
        _synchronizingSelection = YES;
        self.cursor.offset = globalRow;
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
    return self.table.componentTables.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self componentTableAtSection:section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MPWTableRowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MPWTableRowCellIdentifier
                                                                     forIndexPath:indexPath];
    MPWTable *component=[self componentTableAtSection:indexPath.section];
    [cell configureWithColumns:component.columns
                           row:indexPath.item
                     rowObject:[component objectAtIndex:indexPath.item]
                    typeMapper:self.type2Control
                     tableView:self];
    BOOL form=[self usesFormPresentation];
    NSDictionary *valueMetadata=component.columns.count > 1
        ? [component.columns[1] presentationMetadataAtIndex:indexPath.item] : @{};
    NSString *controlKind=valueMetadata[MPWPresentationControlKey];
    BOOL controlPrefersStack=[controlKind isEqual:@"segmented"] || [controlKind isEqual:@"multiline"];
    BOOL stacked=form && (CGRectGetWidth(collectionView.bounds) < 350 || controlPrefersStack);
    BOOL first=indexPath.item == 0;
    BOOL last=indexPath.item + 1 == component.count;
    cell.columnStack.axis=stacked ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal;
    cell.columnStack.distribution=form ? UIStackViewDistributionFill : UIStackViewDistributionFillEqually;
    cell.columnStack.alignment=stacked ? UIStackViewAlignmentFill : UIStackViewAlignmentCenter;
    collectionView.backgroundColor=form ? [UIColor systemGroupedBackgroundColor] : [UIColor systemBackgroundColor];
    cell.backgroundColor=form ? [UIColor secondarySystemGroupedBackgroundColor] : [UIColor systemBackgroundColor];
    cell.separator.hidden=form && last;
    cell.layer.cornerRadius=form && (first || last) ? 10 : 0;
    cell.layer.masksToBounds=form && (first || last);
    if (form) {
        CACornerMask corners=0;
        if (first) { corners |= kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner; }
        if (last) { corners |= kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner; }
        cell.layer.maskedCorners=corners;
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier=[kind isEqual:UICollectionElementKindSectionFooter] ? MPWTableFooterIdentifier : MPWTableHeaderIdentifier;
    MPWTableHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                   withReuseIdentifier:identifier
                                                                          forIndexPath:indexPath];
    MPWTable *component=[self componentTableAtSection:indexPath.section];
    if ([self usesFormPresentation]) {
        header.backgroundColor=[UIColor clearColor];
        NSString *text=[kind isEqual:UICollectionElementKindSectionFooter]
            ? component.itemStructure.documentation
            : component.tableIdentifier;
        [header configureWithText:text footer:[kind isEqual:UICollectionElementKindSectionFooter]];
    } else {
        header.backgroundColor=[UIColor systemBackgroundColor];
        [header configureWithColumns:component.columns];
    }
    return header;
}

#pragma mark layout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width=MAX(0, CGRectGetWidth(collectionView.bounds));
    if ([self usesFormPresentation]) {
        width=MAX(0,width-40);
        MPWTable *component=[self componentTableAtSection:indexPath.section];
        NSDictionary *metadata=component.columns.count > 1 ? [component.columns[1] presentationMetadataAtIndex:indexPath.item] : @{};
        NSString *kind=metadata[MPWPresentationControlKey];
        BOOL tall=width < 310 || [kind isEqual:@"segmented"] || [kind isEqual:@"multiline"];
        return CGSizeMake(width,tall ? 86 : 52);
    }
    return CGSizeMake(width, MPWTableRowHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
 referenceSizeForHeaderInSection:(NSInteger)section
{
    if (![self usesFormPresentation]) {
        return self.tableColumns.count ? CGSizeMake(CGRectGetWidth(collectionView.bounds), MPWTableHeaderHeight) : CGSizeZero;
    }
    NSString *title=[self componentTableAtSection:section].tableIdentifier;
    return CGSizeMake(CGRectGetWidth(collectionView.bounds),title.length ? 32 : 12);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
 referenceSizeForFooterInSection:(NSInteger)section
{
    if (![self usesFormPresentation]) { return CGSizeZero; }
    NSString *footer=[self componentTableAtSection:section].itemStructure.documentation;
    return footer.length ? CGSizeMake(CGRectGetWidth(collectionView.bounds),56) : CGSizeZero;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return [self usesFormPresentation] ? UIEdgeInsetsMake(0,20,0,20) : UIEdgeInsetsZero;
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
    [_valueChangeHandler release];
    [_activationHandler release];
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

+ (MPWStructureTable *)formTestTable
{
    MPWVariableDefinition *name = [[[MPWVariableDefinition alloc]
                                     initWithName:@"name" type:[MPWTypeDefinition idType]] autorelease];
    name.title = @"Name";
    name.operations = MPWRESTVerbsReadWrite;

    MPWVariableDefinition *enabled = [[[MPWVariableDefinition alloc]
                                        initWithName:@"enabled"
                                        type:[MPWTypeDefinition descriptorForObjcCode:'B']] autorelease];
    enabled.title = @"Enabled";
    enabled.operations = MPWRESTVerbsReadWrite;

    MPWVariableDefinition *choice = [[[MPWVariableDefinition alloc]
                                       initWithName:@"choice"
                                       type:[MPWTypeDefinition descriptorForTypeName:@"int"]] autorelease];
    choice.title = @"Choice";
    choice.operations = MPWRESTVerbsReadWrite;
    choice.presentationMetadata = @{ MPWPresentationAllowedValuesKey: @[ @0, @1 ],
                                     MPWPresentationDisplayValuesKey: @[ @"First", @"Second" ] };

    MPWStructureDefinition *main = [MPWStructureDefinition structureWithName:@"Main"
                                                                        fields:@[ name, enabled, choice ]];
    MPWVariableDefinition *section = [[[MPWVariableDefinition alloc] initWithName:@"main" type:main] autorelease];
    section.title = @"MAIN";
    MPWStructureDefinition *definition = [MPWStructureDefinition structureWithName:@"FormTest"
                                                                             fields:@[ section ]];
    MPWRawDictStore *store = [MPWRawDictStore storeWithDictionary:
                              [[@{ @"name": @"Ada", @"enabled": @YES, @"choice": @1 } mutableCopy] autorelease]];
    return [MPWStructureTable tableWithStructureDefinition:definition store:store];
}

+ (MPWTableRowCell *)formCellForTable:(MPWStructureTable *)table row:(NSUInteger)row tableView:(MPWTableView *)tableView
{
    MPWTable *component = [table componentTableAtIndex:0];
    MPWTableRowCell *cell = [[[MPWTableRowCell alloc] initWithFrame:CGRectMake(0, 0, 390, 52)] autorelease];
    [cell configureWithColumns:component.columns
                           row:row
                    typeMapper:[MPWUIKitUIGenerator defaultTypes2UIMapper]
                     tableView:tableView];
    return cell;
}

// 11. Composite tables are rendered as collection-view sections, while each
// component remains a normal table with local rows and columns.
+ (void)testCompositeTableComponentsBecomeSections
{
    MPWStructureTable *table = [self formTestTable];
    MPWTableView *view = [[[MPWTableView alloc] initWithFrame:CGRectMake(0, 0, 390, 700)] autorelease];
    [view setTable:table];
    INTEXPECT([view numberOfSectionsInCollectionView:view], table.componentTables.count, @"one section per component table");
    INTEXPECT([view collectionView:view numberOfItemsInSection:0], 3, @"one item per structure field");
}

// 12 & 13. Declared per-row type and metadata select the control even though
// every value is exposed through the same heterogeneous value column.
+ (void)testFormRowsUseExpectedLabelsAndControlCategories
{
    MPWStructureTable *table = [self formTestTable];
    MPWTableRowCell *name = [self formCellForTable:table row:0 tableView:nil];
    MPWTableRowCell *enabled = [self formCellForTable:table row:1 tableView:nil];
    MPWTableRowCell *choice = [self formCellForTable:table row:2 tableView:nil];

    IDEXPECT([(UILabel *)name.presentations[0] text], @"Name", @"field title appears in label column");
    EXPECTTRUE([name.presentations[1] isKindOfClass:[UITextField class]], @"string field uses text editor");
    EXPECTTRUE([enabled.presentations[1] isKindOfClass:[UISwitch class]], @"boolean field uses switch");
    EXPECTTRUE([choice.presentations[1] isKindOfClass:[UISegmentedControl class]], @"allowed values use segmented control");
}

// 14. Every supported editable control writes through its actual table-column
// binding.  There are no integer tags or field-name switches in this path.
+ (void)testGeneratedControlsWriteBackThroughStructureValueColumn
{
    MPWStructureTable *table = [self formTestTable];
    MPWTableView *view = [[[MPWTableView alloc] initWithFrame:CGRectMake(0, 0, 390, 700)] autorelease];
    [view setTable:table];
    MPWTableColumn *value = [[table componentTableAtIndex:0] columnForKey:@"value"];

    MPWTableRowCell *nameCell = [self formCellForTable:table row:0 tableView:view];
    UITextField *field = (id)nameCell.presentations[1];
    field.text = @"Grace";
    [[field.allTargets anyObject] performSelector:@selector(controlValueChanged:) withObject:field];
    IDEXPECT([value objectAtIndex:0], @"Grace", @"text editor writes store value");

    MPWTableRowCell *switchCell = [self formCellForTable:table row:1 tableView:view];
    UISwitch *toggle = (id)switchCell.presentations[1];
    toggle.on = NO;
    [[toggle.allTargets anyObject] performSelector:@selector(controlValueChanged:) withObject:toggle];
    IDEXPECT([value objectAtIndex:1], @NO, @"switch writes store value");

    MPWTableRowCell *choiceCell = [self formCellForTable:table row:2 tableView:view];
    UISegmentedControl *segments = (id)choiceCell.presentations[1];
    segments.selectedSegmentIndex = 0;
    [[segments.allTargets anyObject] performSelector:@selector(controlValueChanged:) withObject:segments];
    IDEXPECT([value objectAtIndex:2], @0, @"segmented control writes store value");
}

// 15. A reload reconstructs presentations from the store instead of retaining
// a copied form value.
+ (void)testReloadReadsUpdatedStoreValue
{
    MPWStructureTable *table = [self formTestTable];
    MPWTableColumn *value = [[table componentTableAtIndex:0] columnForKey:@"value"];
    [value replaceObjectAtIndex:0 withObject:@"Katherine"];
    MPWTableView *view = [[[MPWTableView alloc] initWithFrame:CGRectMake(0, 0, 390, 700)] autorelease];
    [view setTable:table];
    [view modelDidChange:nil];
    MPWTableRowCell *cell = (id)[view collectionView:view
                                  cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    IDEXPECT([(UITextField *)cell.presentations[1] text], @"Katherine", @"reload reads current store value");
}

// 16. Reconfiguration removes the old control tree and bindings before adding
// presentations for the new row.
+ (void)testCellReuseDropsOldPresentationsAndValues
{
    MPWStructureTable *table = [self formTestTable];
    MPWTable *component = [table componentTableAtIndex:0];
    MPWTableRowCell *cell = [self formCellForTable:table row:0 tableView:nil];
    NSArray *oldPresentations = [[cell.presentations copy] autorelease];
    [cell configureWithColumns:component.columns
                           row:1
                    typeMapper:[MPWUIKitUIGenerator defaultTypes2UIMapper]
                     tableView:nil];
    INTEXPECT(cell.presentations.count, 2, @"reuse has only the current row presentations");
    EXPECTNIL([oldPresentations[0] superview], @"old label removed from cell hierarchy");
    EXPECTNIL([oldPresentations[1] superview], @"old editor removed from cell hierarchy");
    IDEXPECT([(UILabel *)cell.presentations[0] text], @"Enabled", @"reused label contains new row value");
    EXPECTTRUE([cell.presentations[1] isKindOfClass:[UISwitch class]], @"reused editor has new row type");
}

// 18. The generic form policy switches between horizontal and stacked rows;
// both stacks remain fully constrained.
+ (void)testWideAndNarrowFormLayoutsAreUnambiguous
{
    MPWStructureTable *table = [self formTestTable];
    for (NSNumber *widthValue in @[ @430, @300 ]) {
        CGFloat width = widthValue.doubleValue;
        MPWTableView *view = [[[MPWTableView alloc] initWithFrame:CGRectMake(0, 0, width, 700)] autorelease];
        view.presentationStyle = MPWTablePresentationStyleForm;
        [view setTable:table];
        NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:0];
        MPWTableRowCell *cell = (id)[view collectionView:view cellForItemAtIndexPath:path];
        CGSize size = [view collectionView:view layout:view.collectionViewLayout sizeForItemAtIndexPath:path];
        cell.frame = CGRectMake(0, 0, size.width, size.height);
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        BOOL shouldStack = width < 350;
        INTEXPECT(cell.columnStack.axis,
                  shouldStack ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal,
                  @"axis follows available width");
        EXPECTFALSE(cell.columnStack.hasAmbiguousLayout, @"form row stack has unambiguous constraints");
    }
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
        @"testCompositeTableComponentsBecomeSections",
        @"testFormRowsUseExpectedLabelsAndControlCategories",
        @"testGeneratedControlsWriteBackThroughStructureValueColumn",
        @"testReloadReadsUpdatedStoreValue",
        @"testCellReuseDropsOldPresentationsAndValues",
        @"testWideAndNarrowFormLayoutsAreUnambiguous",
    ];
}

@end
