//
//  NSViewAdditions.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.03.19.
//

#import "NSViewAdditions.h"

@implementation NSView(Additions)


-openInWindow:(NSString*)windowName
{
    NSWindow *theWindow=[[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500)
                                                    styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable
                                                      backing:NSBackingStoreBuffered defer:NO];
    [theWindow setTitle:windowName];
    [theWindow setContentView:self];
    [theWindow makeKeyAndOrderFront:nil];
    return self;
}

+openInWindow:(NSString*)name
{
    NSView *aView = [[self alloc] initWithFrame:NSMakeRect(0, 0, 490, 490)];
    [aView openInWindow:name];
    return aView ;
}


@end
