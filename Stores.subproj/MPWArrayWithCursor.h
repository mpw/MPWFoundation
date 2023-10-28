//
//  MPWArrayWithCursor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 22.10.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWArrayWithCursor : NSMutableArray

@property (nonatomic,assign) unsigned long offset;


@end

NS_ASSUME_NONNULL_END
