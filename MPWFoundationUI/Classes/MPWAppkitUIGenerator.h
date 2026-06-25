//
//  MPWAppkitUIGenertor.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class NSView;

NS_ASSUME_NONNULL_BEGIN

@interface MPWAppkitUIGenerator : MPWAbstractUIGenerator

@property (nonatomic,strong) NSView *rootView;

+(MPWTypeToObjectMapper*)defaultTypes2UIMapper;


@end

NS_ASSUME_NONNULL_END
