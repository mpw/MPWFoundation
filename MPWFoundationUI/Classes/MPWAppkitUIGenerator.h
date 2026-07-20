//
//  MPWAppkitUIGenertor.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.05.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class NSView,NSColor;

NS_ASSUME_NONNULL_BEGIN

@interface MPWAppkitUIGenerator : MPWAbstractUIGenerator

/// The top-level stack view the generated UI is written into.  Either the view
/// we were handed, if that can arrange generated views itself, or one we create
/// and constrain inside baseView.
@property (nonatomic,strong) NSView *rootView;

/// The externally supplied view we were handed, when it isn't itself a view
/// that arranges what we generate (a plain container, e.g. a view controller's
/// view).  nil when rootView is the view we were given.
@property (nonatomic,strong,nullable) NSView *baseView;

/// Minimum width applied to generated value controls (text fields, popups), so
/// a generated form doesn't collapse to the width of its current contents.
/// Defaults to 280; set to 0 to leave controls at their intrinsic size.
@property (nonatomic,assign) CGFloat valueControlMinimumWidth;

/// Margin between a created rootView and the baseView containing it, and the
/// spacing between the top-level generated views.  Both default to 24.
@property (nonatomic,assign) CGFloat contentInset,contentSpacing;

/// Tint for controls whose action discards data, currently the reset button.
/// Defaults to the system red.
@property (nonatomic,strong) NSColor *destructiveActionColor;

+(MPWTypeToObjectMapper*)defaultTypes2UIMapper;


@end


@interface NSView(UICreation)

-(MPWAppkitUIGenerator*)uiGenerator;

@end
NS_ASSUME_NONNULL_END
