//
//  MPWAbstractUIGenerator.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWTypeToObjectMapper;

@interface MPWAbstractUIGenerator : MPWFlattenStream

@property (nonatomic,strong) MPWTypeToObjectMapper *type2view;

@end

NS_ASSUME_NONNULL_END
