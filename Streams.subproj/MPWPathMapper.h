//
//  MPWPathMapper.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.05.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWPathMapper : MPWFilter

@property (nonatomic,strong) id <MPWIdentifying> prefix;

@end

NS_ASSUME_NONNULL_END
