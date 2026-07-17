//
//  MPWTableColumn.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWTypeDefinition;

@interface MPWTableColumn : NSObject

@property (nonatomic, assign) bool editable;
@property (nonatomic, assign) bool visible;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) MPWTypeDefinition *type;

objectAccessor_h( NSString*, title, setTitle)

-(id)objectAtIndex:(NSUInteger)anIndex;
-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:(nullable id)object;
/// Per-row queries let heterogeneous projections (notably structure forms)
/// retain the ordinary homogeneous-column API as their default behavior.
-(nullable MPWTypeDefinition*)typeAtIndex:(NSUInteger)anIndex;
-(NSDictionary*)presentationMetadataAtIndex:(NSUInteger)anIndex;
-(BOOL)isEditableAtIndex:(NSUInteger)anIndex;

@end

NS_ASSUME_NONNULL_END
