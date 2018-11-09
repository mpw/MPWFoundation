//
//  MPWCompositeStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.11.18.
//

#import <MPWFoundation/MPWAbstractStore.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWCompositeStore : MPWAbstractStore

+(instancetype)stores:(NSArray*)stores;

@end

NS_ASSUME_NONNULL_END
