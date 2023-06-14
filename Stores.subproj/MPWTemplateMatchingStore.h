//
//  MPWTemplateMatchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWTemplateMatchingStore : MPWAbstractStore

@property (nonatomic, strong) id target;
@property (nonatomic, strong) id additionalParam;
@property (nonatomic, assign) bool addRef,useParam;

-(id)at:(id<MPWReferencing>)aReference for:target with:(id*)extraParams count:(int)extraParamCount;


@end



NS_ASSUME_NONNULL_END
