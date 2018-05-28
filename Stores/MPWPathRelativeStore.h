//
//  MPWPathRelativeStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWGenericReference;

@interface MPWPathRelativeStore : MPWMappingStore

@property (nonatomic, strong) MPWGenericReference* baseReference;

@end
