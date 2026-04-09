//
//  MPWInstanceVariableDefinition.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 04.04.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWInstanceVariableDefinition : MPWVariableDefinition

@property (nonatomic, assign) long offset;

-initWithName:(NSString*)newName offset:(long)newOffset type:(MPWTypeDefinition*)newType;
-(void*)pointerToVarRelativeToBase:(void*)base;


@end

NS_ASSUME_NONNULL_END
