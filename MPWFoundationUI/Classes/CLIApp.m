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

- (void) applicationWillFinishLaunching: (NSNotification *)notification {
    [self createMenu];
}


-(instancetype)init
{
    self=[super init];
    [self setDelegate:self];
    [self setActivationPolicy:0];
    return self;
}

-(void)runFromCLI:(NSWindow*)window
{
    [window makeKeyAndOrderFront:self];
    [self activateIgnoringOtherApps:YES];
    [self run];
}

+(void)runFromCLI:(NSWindow*)window
{
    [[self sharedApplication] runFromCLI:window];
}

@end
