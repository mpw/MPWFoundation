//
//  MPWTypeToObjectMapper.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWTypeToObjectMapper : MPWAbstractStore

-(id)atType:(MPWTypeDefinition*)type;

@end

NS_ASSUME_NONNULL_END
