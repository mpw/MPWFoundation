//
//  MPWTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStructureDefinition,MPWTableColumn;

@interface MPWTable : NSObject

objectAccessor_h(NSArray<MPWTableColumn*>*, columns, setColumns )

-(void)rowsDo:aBlock;

@end

NS_ASSUME_NONNULL_END
