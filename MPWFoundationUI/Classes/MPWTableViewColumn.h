//
//  MPWTableViewColumn.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 19.05.24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWPropertyBinding,MPWTableColumn;

@interface MPWTableViewColumn : NSTableColumn

@property (nonatomic, strong)  MPWTableColumn *tableColumn;

-(id)valueForTarget:(id)anObject;

@end

NS_ASSUME_NONNULL_END
