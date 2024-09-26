//
//  MPWBasedStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26.09.24.
//

#import <MPWFoundation/MPWAbstractStore.h>

@protocol MPWReferencing;

NS_ASSUME_NONNULL_BEGIN

@interface MPWBasedStore : MPWAbstractStore

@property (nonatomic, strong ) id <MPWReferencing> baseReference;
@property (nonatomic, strong ) id baseObject;

@end

NS_ASSUME_NONNULL_END
