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

-(NSScrollView*)inScrollView:(NSRect)scrollViewRect
{
    NSScrollView *sv=[[[NSScrollView alloc] initWithFrame:scrollViewRect] autorelease];
    [sv setDocumentView:self];
    return sv;
}

-openInWindow:(NSString*)windowName
{
    NSRect r=[self frame];
    NSRect defaultRect = [self defaultWindowRect];
    if ( r.size.width == 0 || r.size.height == 0) {
        r.size = defaultRect.size;
    }
    r.size.width += 5;
    r.size.height += 5;
    if ( r.origin.x == 0 || r.origin.y == 0) {
        r.origin = defaultRect.origin;
    }

    NSWindow *theWindow=[[NSWindow alloc] initWithContentRect:r
                                                    styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable|NSWindowStyleMaskMiniaturizable
                                                      backing:NSBackingStoreBuffered defer:NO];
    [theWindow setTitle:windowName];
//    [[theWindow contentView] addSubview:self];
    [theWindow setContentView:self];
    [theWindow makeKeyAndOrderFront:nil];
    return theWindow;
}

-main:args
{
    NSLog(@"-[%@ main:]",[self class]);
    NSWindow *w=[self openInWindow:@"Window"];
    NSLog(@"window: %@",w);
    return [w main:args];
}

-(int)runWithStdin:source Stdout:target
{
    return [[self main:nil] intValue];
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
