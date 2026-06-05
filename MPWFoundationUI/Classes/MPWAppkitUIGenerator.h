//
//  MPWAppkitUIGenertor.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class NSView,MPWTypeToControlMapper;

NS_ASSUME_NONNULL_BEGIN

@interface MPWAppkitUIGenerator : MPWFlattenStream

@property (nonatomic,strong) NSView *rootView;
@property (nonatomic,strong) MPWTypeToControlMapper *type2view;

@end

NS_ASSUME_NONNULL_END
