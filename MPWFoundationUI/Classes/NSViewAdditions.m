//
//  NSViewAdditions.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.03.19.
//

#import "NSViewAdditions.h"
#import "MPWWindowController.h"



@implementation NSView(Additions)

-(NSRect)defaultWindowRect
{
    return NSMakeRect(50, 50, 700, 400);
}

-openInWindow:(NSString*)windowName
{
    NSWindow *theWindow=[[NSWindow alloc] initWithContentRect:[self defaultWindowRect]
                                                    styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable|NSWindowStyleMaskMiniaturizable
                                                      backing:NSBackingStoreBuffered defer:NO];
    [theWindow setTitle:windowName];
    [theWindow setContentView:self];
    [theWindow makeKeyAndOrderFront:nil];
    return theWindow;
}

-openInWindowController:(NSString*)windowName
{
    NSWindow *window=[self openInWindow:windowName];
    MPWWindowController* c = [[[MPWWindowController alloc] initWithWindow:window] autorelease];
    c.view = self;
    return c;
}

+openInWindow:(NSString*)name
{
    NSView *aView = [[self alloc] initWithFrame:NSMakeRect(0, 0, 490, 490)];
    [aView openInWindow:name];
    return aView ;
}


@end
