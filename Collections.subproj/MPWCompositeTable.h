//
//  MPWCompositeTable.h
//  MPWFoundation
//

#import <MPWFoundation/MPWTable.h>

NS_ASSUME_NONNULL_BEGIN

/// A table composed from ordered component tables.  Presenters can render each
/// component as a logical group without importing presentation-system sections
/// into the table or storage protocols.
@interface MPWCompositeTable : MPWTable {
    NSArray<MPWTable*> *_componentTables;
}

@property (nonatomic,retain) NSArray<MPWTable*> *componentTables;

+(instancetype)tableWithComponentTables:(NSArray<MPWTable*>*)tables;
-(instancetype)initWithComponentTables:(NSArray<MPWTable*>*)tables;

@end

NS_ASSUME_NONNULL_END
