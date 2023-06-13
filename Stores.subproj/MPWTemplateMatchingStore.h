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
@property (nonatomic, assign) bool addRef;
@end


NS_ASSUME_NONNULL_END
