//
//  MPWTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStructureDefinition;

@interface MPWTable : NSObject

objectAccessor_h(NSArray*, columns, setColumns )
@end

NS_ASSUME_NONNULL_END
