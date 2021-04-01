//
//  MPWWindowController.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 01.04.21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWWindowController : NSWindowController

@property (nonatomic,strong) NSString *titleAddition;
@property (nonatomic,strong) NSView *view;

@end

NS_ASSUME_NONNULL_END
