//
//  MPWMergingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/11/18.
//

#import <MPWFoundation/MPWMappingStore.h>

@interface MPWMergingStore : MPWMappingStore

-mergeNew:(nonnull)newObject into:(nonnull)existingObject forReference:(id <MPWReferencing>)aReference;


@end
