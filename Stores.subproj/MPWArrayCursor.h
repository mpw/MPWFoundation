//
//  MPWArrayCursor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.10.23.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWArrayCursor : NSObject <MPWReferencing>

-initWithArray:anArray;

@property (nonatomic, assign) long offset;



@end

NS_ASSUME_NONNULL_END
