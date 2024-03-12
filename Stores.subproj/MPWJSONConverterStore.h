//
//  MPWJSONConverterStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 25.05.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWJSONConverterStore : MPWMappingStore

@property (nonatomic,assign) BOOL up;
@property (nonatomic, assign) bool mutable;
@end

NS_ASSUME_NONNULL_END
