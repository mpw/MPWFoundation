//
//  MPWTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStructureDefinition,MPWTableColumn;

@interface MPWTable : NSObject

objectAccessor_h(NSArray<MPWTableColumn*>*, columns, setColumns )
objectAccessor_h(NSArray<MPWTableColumn*>*, visibleColumns, setVisibleColumns )
objectAccessor_h(NSString*, tableIdentifier, setTableIdentifier )
objectAccessor_h(MPWStructureDefinition*, itemStructure, setItemStructure )

@property (nonatomic,copy,nullable) NSDictionary *presentationMetadata;
@property (nonatomic,readonly) NSArray<MPWTable*> *componentTables;

-(MPWTableColumn*)columnForKey:(NSString*)aKey;
-(void)rowsDo:(void (^)(NSNumber *))block;
-(NSUInteger)count;
-(nullable id)objectAtIndex:(NSUInteger)index;

/// An ordinary table is the one-element degenerate composite.
-(nullable MPWTable*)componentTableAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
