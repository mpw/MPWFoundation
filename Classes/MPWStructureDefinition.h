//
//  MPWStructureDefinition.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import <MPWFoundation/MPWTypeDefinition.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWVariableDefinition;

@interface MPWStructureDefinition : MPWTypeDefinition

+(instancetype)structureWithName:(NSString*)name fields:fieldDefs;
-(instancetype)initWithName:(NSString*)name fields:fieldDefs;

-(instancetype)copyWithFieldIndexes:(NSArray*)fieldIndexes;

/// Leaf reference paths, with nested structures represented as path components.
-(NSArray<NSString*>*)referencePaths;

@property (nonatomic, strong) NSArray<MPWVariableDefinition*>* fields;
/// Human-readable documentation describing this structure.
@property (nonatomic, copy, nullable) NSString *documentation;

@end

NS_ASSUME_NONNULL_END
