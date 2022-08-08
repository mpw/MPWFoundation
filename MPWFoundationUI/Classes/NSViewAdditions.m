//
//  NSViewAdditions.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 27.03.19.
//

#import "NSViewAdditions.h"
#import "MPWWindowController.h"



@implementation NSView(Additions)

-(void)setName:(NSString *)name
{
    self.accessibilityIdentifier = name;
}

-(NSString*)name
{
    return self.accessibilityIdentifier;
}

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

@implementation NSControl(setAction)

-(void)setTheAction:(NSString*)action
{
    [self setAction:NSSelectorFromString(action)];
}



@end

#import "DebugMacros.h"

@interface NSViewAdditionsTesting:NSObject{}
@end

@implementation NSViewAdditionsTesting

+(void)testNameIsMappedToAccessibilityIdentifier
{
    NSView *v=[NSView new];
    EXPECTNIL(v.name,@"no name");
    v.name = @"Hello";
    IDEXPECT(v.name, @"Hello", @"can set name");
    IDEXPECT(v.accessibilityIdentifier, @"Hello", @"name sets accessibilityIdentifier");
    v.accessibilityIdentifier=@"World";
    IDEXPECT(v.accessibilityIdentifier, @"World", @"can set accessibilityIdentifier");
    IDEXPECT(v.name, @"World", @"accessibilityIdentifier also sets name");

    
}

+(NSArray*)testSelectors
{
    return @[
        @"testNameIsMappedToAccessibilityIdentifier",
    ];
}

@end
