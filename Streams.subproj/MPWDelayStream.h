//
//  MPWDelayStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 14/11/2016.
//
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWDelayStream : MPWFilter

@property (atomic, assign)  NSTimeInterval relativeDelay;
@property (atomic, assign)  BOOL synchronous;


@end
