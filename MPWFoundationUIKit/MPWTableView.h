//
//  MPWTableView.h
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 26.06.26.
//

#import <UIKit/UIKit.h>
#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWArrayCursor, MPWReference, MPWTable, MPWTableColumn, MPWTypeToObjectMapper, MPWTableView;

typedef NS_ENUM(NSUInteger, MPWTablePresentationStyle) {
    MPWTablePresentationStyleAutomatic,
    MPWTablePresentationStyleTabular,
    MPWTablePresentationStyleForm,
};

typedef void (^MPWTableValueChangeHandler)(id rowObject, id value, NSDictionary *metadata);
typedef void (^MPWTableActivationHandler)(id rowObject, NSDictionary *metadata);

/// One collection-view item == one table row.  The cell lays its column
/// presentations out in a horizontal stack; it is the only cell class the table
/// needs, since the concrete controls are chosen by the type-to-control mapper.
@interface MPWTableRowCell : UICollectionViewCell

@property (nonatomic, readonly) UIStackView *columnStack;
@property (nonatomic, readonly) NSArray<UIView *> *presentations;

- (void)configureWithColumns:(NSArray<MPWTableColumn *> *)columns
                         row:(NSUInteger)row
                  typeMapper:(MPWTypeToObjectMapper *)typeMapper
                   tableView:(nullable MPWTableView *)tableView;

@end


/// UIKit counterpart of the AppKit MPWTableView.  It presents an MPWTable: one
/// row per collection-view item, one editor/value view per MPWObjectColumn.
/// UICollectionView is only the rendering substrate; the semantic surface is
/// "presents an MPWTable", just like the AppKit class.
@interface MPWTableView : UICollectionView
    <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
     ModelDidChange, SelectionDidChange>

@property (nonatomic, strong, nullable) MPWReference *binding;
@property (nonatomic, strong, nullable) MPWArrayCursor *cursor;
@property (nonatomic, copy, nullable) NSArray *(^valueFilter)(id object);
@property (nonatomic, assign) MPWTablePresentationStyle presentationStyle;
@property (nonatomic, copy, nullable) MPWTableValueChangeHandler valueChangeHandler;
@property (nonatomic, copy, nullable) MPWTableActivationHandler activationHandler;

- (void)setTable:(MPWTable *)table;
- (nullable id)objectAtRow:(NSUInteger)row;
- (nullable id)selectedObject;

@end

NS_ASSUME_NONNULL_END
