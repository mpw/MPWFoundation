//
//  MPWTableColumn.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWTableColumn : NSObject

@property (nonatomic, assign) bool editable;
@property (nonatomic, strong) NSString *key;

objectAccessor_h( NSString*, title, setTitle)

@end

NS_ASSUME_NONNULL_END
