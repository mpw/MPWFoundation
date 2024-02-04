//
//  MPWStringTemplate.h
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 04.02.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWStringTemplate : NSObject

+(instancetype)templateWithString:(NSString*)s;
-(instancetype)initWithString:(NSString*)s;


@end

NS_ASSUME_NONNULL_END
