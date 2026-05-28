//
//  MPWAppkitUIGenertor.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class NSView;

NS_ASSUME_NONNULL_BEGIN

@interface MPWAppkitUIGenerator : MPWFlattenStream

@property (nonatomic,strong) NSView *rootView;

@end

NS_ASSUME_NONNULL_END
