//
//  CLIApp.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 20.08.22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLIApp : NSApplication <NSApplicationDelegate>

@property (assign) bool terminateFlag;

@end

NS_ASSUME_NONNULL_END
