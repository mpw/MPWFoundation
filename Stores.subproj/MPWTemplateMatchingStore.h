//
//  MPWTemplateMatchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWTemplateMatchingStore : MPWAbstractStore

@property (nonatomic, weak) id target;

-(id)at:(id<MPWReferencing>)aReference for:target with:(id*)extraParams count:(int)extraParamCount;


@end



NS_ASSUME_NONNULL_END
