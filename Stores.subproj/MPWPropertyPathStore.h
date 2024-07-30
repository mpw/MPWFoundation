//
//  MPWPropertyPathStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 06.06.23.
//

#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWPropertyPathDefs.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWPropertyPathStore : MPWAbstractStore

-(void)createMatchers:(PropertyPathDef*)defs count:(int)numDefs verb:(MPWRESTVerb)verb;
-(id)at:(id<MPWIdentifying>)aReference verb:(MPWRESTVerb)verb for:target with:(id*)args count:(int)count;
void installPropertyPathsOnClass( Class targetClass, PropertyPathDef* getters,int getterCount ,PropertyPathDef* setters, int setterCount );

@end

NS_ASSUME_NONNULL_END
