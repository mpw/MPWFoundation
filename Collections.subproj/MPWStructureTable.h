//
//  MPWStructureTable.h
//  MPWFoundation
//
//  A table-valued projection of MPWStructureDefinition x MPWStorage.
//

#import <MPWFoundation/MPWCompositeTable.h>
#import <MPWFoundation/MPWTableColumn.h>
#import <MPWFoundation/MPWAbstractStore.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStructureDefinition, MPWVariableDefinition;

FOUNDATION_EXPORT NSString * const MPWPresentationControlKey;
FOUNDATION_EXPORT NSString * const MPWPresentationAllowedValuesKey;
FOUNDATION_EXPORT NSString * const MPWPresentationDisplayValuesKey;
FOUNDATION_EXPORT NSString * const MPWPresentationPlaceholderKey;
FOUNDATION_EXPORT NSString * const MPWPresentationActionKey;
FOUNDATION_EXPORT NSString * const MPWPresentationDestructiveKey;
FOUNDATION_EXPORT NSString * const MPWPresentationStyleKey;

@interface MPWStructureTable : MPWCompositeTable

@property (nonatomic,retain,readonly) MPWStructureDefinition *structureDefinition;
@property (nonatomic,retain,readonly) id <MPWStorage> store;
@property (nonatomic,retain,readonly) NSArray<MPWVariableDefinition*> *visibleFields;

+(instancetype)tableWithStructureDefinition:(MPWStructureDefinition*)definition
                                       store:(id <MPWStorage>)store;
-(instancetype)initWithStructureDefinition:(MPWStructureDefinition*)definition
                                      store:(id <MPWStorage>)store;

@end

@interface MPWStructureLabelColumn : MPWTableColumn
@end

@interface MPWStructureValueColumn : MPWTableColumn
@end

NS_ASSUME_NONNULL_END
