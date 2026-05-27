//
//  MPWTypeToControlMapper.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.05.26.
//

#import <MPWFoundation/MPWFoundation.h>

@class NSControl,MPWTypeDefinition;

NS_ASSUME_NONNULL_BEGIN

@interface MPWTypeToControlMapper : NSObject

-(NSControl*)controlForType:(MPWTypeDefinition*)typeDefinition;

@end

NS_ASSUME_NONNULL_END
