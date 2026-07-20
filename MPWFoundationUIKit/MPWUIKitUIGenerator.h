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

-(UIView*)rootView;

@end

NS_ASSUME_NONNULL_END
