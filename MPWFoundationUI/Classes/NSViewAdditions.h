//
//  NSViewAdditions.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.03.19.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView(Additions)
-(NSWindow*)openInWindow:(NSString*)windowName;
-(NSWindowController*)openInWindowController:(NSString*)windowName;

@property NSString *name;

@end

NS_ASSUME_NONNULL_END
