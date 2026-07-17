//
//  MPWUIKitUIGenerator.h
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class UIView;

NS_ASSUME_NONNULL_BEGIN

@interface MPWUIKitUIGenerator : MPWAbstractUIGenerator

/// Type-name → UIKit-control mapper, analogous to
/// +[MPWAppkitUIGenerator defaultTypes2UIMapper].  Shared by the form generator
/// and by MPWTableView so column/field presentations stay consistent.
+(MPWTypeToObjectMapper*)defaultTypes2UIMapper;
-(UIView*)rootView;

@end

NS_ASSUME_NONNULL_END
