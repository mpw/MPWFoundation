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

+(instancetype)structureWithFields:fieldDefs;
-(instancetype)initWithFields:fieldDefs;


@property (nonatomic, strong) NSArray<MPWVariableDefinition*>* fields;

@end

NS_ASSUME_NONNULL_END
