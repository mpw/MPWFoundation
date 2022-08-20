//
//  CLIApp.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 20.08.22.
//

#import "CLIApp.h"

@implementation CLIApp

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app
{
    return YES;
}

-(void)createMenu {
    NSMenu *menubar = [[NSMenu alloc]init];
    NSMenuItem *menuBarItem = [[NSMenuItem alloc] init];
    [menubar addItem:menuBarItem];
    [self setMainMenu:menubar];
    NSMenu *myMenu = [[NSMenu alloc]init];
    NSString* quitTitle = @"Quit";
    NSMenuItem* quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                          action:@selector(terminate:) keyEquivalent:@"q"];
    [myMenu addItem:quitMenuItem];
    [menuBarItem setSubmenu:myMenu];
}

-(void)terminate:(id)sender
{
    self.terminateFlag = YES;
    NSLog(@"terminate:");
    [self performSelectorOnMainThread:@selector(tickle) withObject:nil waitUntilDone:NO];
}

-(void)tickle { NSLog(@"tickle"); }

- (void) applicationWillFinishLaunching: (NSNotification *)notification {
    [self createMenu];
}

-(BOOL)shouldTerminate
{
    return [[self windows] count] == 0 || self.terminateFlag;
}

-(void)run
{
    [self finishLaunching];
    self.terminateFlag = NO;
    NSAutoreleasePool *pool=nil;
    do
    {
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
        
        NSEvent *event =
        [self
         nextEventMatchingMask:NSEventMaskAny
         untilDate:[NSDate dateWithTimeIntervalSinceNow:10]
         inMode:NSDefaultRunLoopMode
         dequeue:YES];
        if ( event ) {
            [self sendEvent:event];
            [self updateWindows];
        }
    } while (!self.shouldTerminate);
}

-(instancetype)init
{
    self=[super init];
    [self setDelegate:self];
    [self setActivationPolicy:0];
    return self;
}


-(void)runFromCLI:(NSWindow*)windowOrView
{
    if ( [windowOrView isKindOfClass:[NSView class]]) {
        windowOrView = [(NSView*)windowOrView openInWindow:@"CLI"];
    }
    [windowOrView makeKeyAndOrderFront:self];
    [self activateIgnoringOtherApps:YES];
    [self run];
}

@end
