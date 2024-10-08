//
//  MPWObjectStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 22.11.20.
//

#import <MPWFoundation/MPWBasedStore.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWPropertyStore : MPWBasedStore

+(instancetype)storeWithObject:anObject;
-(instancetype)initWithObject:anObject;

@property (readonly)  id object;
-(NSArray*)propertyNames;

@end

NS_ASSUME_NONNULL_END
