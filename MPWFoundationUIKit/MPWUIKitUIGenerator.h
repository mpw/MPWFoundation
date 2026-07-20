//
//  MPWUIKitUIGenerator.h
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class UIView,UIColor;

NS_ASSUME_NONNULL_BEGIN

@interface MPWUIKitUIGenerator : MPWAbstractUIGenerator

/// The externally supplied view we were handed, when it isn't itself a view
/// that arranges what we generate (a plain container, e.g. a view controller's
/// view).  nil when rootView is the view we were given.
@property (nonatomic,strong,nullable) UIView *baseView;

/// Margin between a created rootView and the baseView containing it, and the
/// spacing between the top-level generated views.  Default to 0 and 12: a form
/// fills its container, since the sections do the insetting.
@property (nonatomic,assign) CGFloat contentInset,contentSpacing;

/// Tint for controls whose action discards data, currently the reset button.
/// Defaults to the system red.
@property (nonatomic,strong) UIColor *destructiveActionColor;

/// Background given to a baseView that doesn't have one, so a generated form
/// sits on the system's grouped background rather than on nothing.
@property (nonatomic,strong) UIColor *formBackgroundColor;

/// Type-name → UIKit-control mapper, analogous to
/// +[MPWAppkitUIGenerator defaultTypes2UIMapper].  Shared by the form generator
/// and by MPWTableView so column/field presentations stay consistent.
+(MPWTypeToObjectMapper*)defaultTypes2UIMapper;

/// Mapping a *single* component is a plain method backed by the type mapper —
/// the stream is only for building nested structures.  Clients that need one
/// control keep a generator instance rather than calling a class-side procedure.
-(UIView*)controlForType:(nullable MPWTypeDefinition*)type
    presentationMetadata:(nullable NSDictionary*)metadata;
-(UIView*)controlForType:(nullable MPWTypeDefinition*)type
    presentationMetadata:(nullable NSDictionary*)metadata
       representedObject:(nullable id)representedObject;

/// Control for a structure field, honouring its `values` (enumeration) and
/// presentation metadata, and binding it to the generator's store.
-(UIView*)controlForField:(MPWVariableDefinition*)field;
-(void)bindControl:(UIView*)control toField:(MPWVariableDefinition*)field;

/// The top-level view the generated UI is written into.  Either the view we
/// were handed, if that can arrange generated views itself, or one we create
/// and constrain inside baseView.
-(UIView*)rootView;

@end


@interface UIView(UICreation)

-(MPWUIKitUIGenerator*)uiGenerator;

@end

NS_ASSUME_NONNULL_END
