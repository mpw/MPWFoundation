//
//  MPWTableColumn.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWTypeDefinition;

@interface MPWTableColumn : NSObject

@property (nonatomic, assign) bool editable;
@property (nonatomic, assign) bool visible;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) MPWTypeDefinition *type;

objectAccessor_h( NSString*, title, setTitle)

@end

NS_ASSUME_NONNULL_END
