//
//  MPWViewHarness.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 16.03.26.
//

#import "MPWViewHarness.h"
#import "MPWView.h"
#import "MPWWindowController.h"

@interface MPWViewHarness()

@property (nonatomic, strong ) NSView *contentView;
@property (nonatomic, assign ) bool autoredisplay;

@end

@implementation MPWViewHarness

-(void)redisplayDisplayingErrors
{
    NSString *errorMsg = @"";
    NSException *error = nil;
    @try {
        [self.contentView display];
        if ( [self.contentView respondsToSelector:@selector(lastException)] ) {
            error = [self.contentView lastException];
        }
    } @catch ( NSException *e ) {
        error = e;
    }
    if (error ) {
        errorMsg = [error description];
    }
    [self.logView setString:errorMsg];
}

-(IBAction)triggerRedisplay:(id)sender
{
    [self redisplayDisplayingErrors];
}


-(instancetype)initWithView:newContentView
{
    self = [super initWithNibName:@"MPWHarness" bundle:[NSBundle bundleForClass:[self class]]];
    self.contentView = newContentView;
    [self view];
    NSLog(@"MPWViewHarness: %p",self);
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self.slotForContentView addSubview:self.contentView];
}

-openInWindow:(NSString*)windowName
{
    NSDocument *doc = [[NSDocumentController sharedDocumentController]   currentDocument];
    NSWindow *window = [self.view openInWindow:windowName];
    MPWWindowController *windowController=[[[MPWWindowController alloc] initWithWindow:window] autorelease];
    windowController.viewController=self;
    [doc addWindowController:windowController];
    return window;
}



@end


@implementation NSView(inHarness)

-inHarness
{
    MPWViewHarness *harness = [[[MPWViewHarness alloc] initWithView:self] autorelease];
    return harness;
}

@end
