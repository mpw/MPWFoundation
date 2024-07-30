//
//  MPWTableColumn.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 19.05.24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWPropertyBinding;

@interface MPWTableColumn : NSTableColumn

@property (nonatomic, strong)  MPWPropertyBinding *binding;

-(id)valueForTarget:(id)anObject;

@end

NS_ASSUME_NONNULL_END
