//
//  MPWDelayStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 14/11/2016.
//
//

#import <MPWFoundation/MPWStream.h>

@interface MPWDelayStream : MPWStream

@property (atomic, assign)  NSTimeInterval relativeDelay;
@property (atomic, assign)  BOOL synchronous;


@end
