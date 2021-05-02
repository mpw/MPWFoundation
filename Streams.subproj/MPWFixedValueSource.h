//
//  MPWFixedValueSource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.05.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWFixedValueSource : MPWFilter

@property (nonatomic, strong) NSArray *values;

-(NSTimer*)fireEvery:(NSTimeInterval)seconds;

@end

NS_ASSUME_NONNULL_END
