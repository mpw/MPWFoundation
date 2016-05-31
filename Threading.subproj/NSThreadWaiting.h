//
//  NSThreadWaiting.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 30/05/16.
//
//

#import <Foundation/Foundation.h>

@interface NSThread(Waiting)

+ (BOOL)sleepForTimeInterval:(NSTimeInterval)ti orUntilConditionIsMet:(NSNumber* (^)(void))conditionBlock;


@end
