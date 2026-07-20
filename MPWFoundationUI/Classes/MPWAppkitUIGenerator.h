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

/// Minimum width applied to generated value controls (text fields, popups), so
/// a generated form doesn't collapse to the width of its current contents.
/// Defaults to 280; set to 0 to leave controls at their intrinsic size.
@property (nonatomic,assign) CGFloat valueControlMinimumWidth;

+(MPWTypeToObjectMapper*)defaultTypes2UIMapper;


@end


@interface NSView(UICreation)

-(MPWAppkitUIGenerator*)uiGenerator;

@end
NS_ASSUME_NONNULL_END
