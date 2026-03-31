//
//  MPWMStats.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.03.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMStats : NSObject

+stats;
-(long)bytesUsed;
+(long)bytesUsed;
+(long)peak;
+(void)resetPeak;

@end

NS_ASSUME_NONNULL_END
