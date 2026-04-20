//
//  MPWFileBrowser.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 06.08.20.
//

#import "MPWFileBrowser.h"
#import "MPWBrowser.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWWindowController.h"

@interface MPWFileBrowser ()

@property (nonatomic,strong)            IBOutlet NSTextView   *text;
@property (nonatomic,strong)            IBOutlet NSScrollView *textScrollView;
@property (nonatomic,strong)            IBOutlet NSImageView  *image;
@property (nonatomic,strong)            IBOutlet NSView       *contentView;
@property (nonatomic,strong)            IBOutlet NSTextView   *errorView;
@property (nonatomic,strong)            IBOutlet NSTextField  *newClassName;

-(IBAction)didSelect:sender;

@end

@implementation MPWFileBrowser

-(instancetype)init
{
    self = [super initWithNibName:@"MPWFileBrowser" bundle:[NSBundle bundleForClass:[self class]]];
    [self view];
    NSLog(@"MPWFileBrowser: %p",self);
    NSLog(@"browser target: %@",self.browser.target);
    NSLog(@"browser action: %@",NSStringFromSelector(self.browser.action));
    return self;
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    NSTextView *text=self.text;
    [self.browser registerForDraggedTypes:@[ NSPasteboardTypeFileURL]];
    [text setAutomaticQuoteSubstitutionEnabled:NO];
    [text setAutomaticLinkDetectionEnabled:NO];
    [text setAutomaticDataDetectionEnabled:NO];
    [text setAutomaticDashSubstitutionEnabled:NO];
    [text setAutomaticTextReplacementEnabled:NO];
    [text setAutomaticSpellingCorrectionEnabled:NO];
    [text setUsesFindPanel:YES];
//    [image setImageScaling:NSImageScaleProportionallyUpOrDown];
//    [text setFont:[NSFont fontWithName:@"Menlo Regular" size:11]];

}

-(MPWReference*)currrentBinding
{
    return (MPWReference*)[self.browser currentReference];
}

-(IBAction)didSelect:(MPWBrowser*)sender
{
    NSString *pathExtensions = [[[[self currrentBinding] path] pathExtension] lowercaseString];
    NSData *value = [[self currrentBinding] value];
    if ( [pathExtensions isEqual:@"png"] || [pathExtensions isEqual:@"jpg"]) {
        [self.image setImage:[[[NSImage alloc] initWithData:value] autorelease]];
        [[[self.contentView subviews] do] removeFromSuperview];
        [self.image setFrameSize:self.contentView.frame.size];
        [self.contentView addSubview:self.image];
    } else {
        [[[self.contentView subviews] do] removeFromSuperview];
        [self.contentView addSubview:self.textScrollView];
        [self.text setString: [value stringValue] ?: @""];
        [self.textScrollView setFrameSize:self.contentView.frame.size];
        [self.textScrollView setNeedsLayout:YES];
        [self.text setNeedsLayout:YES];
        [self.text setNeedsDisplay:YES];
    }
    [[self.delegate ifResponds] didSelect:self];
}

-(void)saveFileContents
{
    if ( [[self.contentView subviews] containsObject:self.textScrollView] ) {
        [[self currrentBinding] setValue:[[self.text string] asData]];
    } else if ( [[self.contentView subviews] containsObject:self.image] ){
        NSString *pathExtensions = [[[[self currrentBinding] path] pathExtension] lowercaseString];
        NSLog(@"can't save image");
    }
}

-(void)setStore:newStore
{
    self.browser.store=newStore;
}

-store
{
    return self.browser.store;
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


-(void)textDidChange:(NSNotification *)notification {
    if ( self.continuous ) {
        [self saveFileContents];
    }
}

-(void)setEditable:(BOOL)isEditable
{
    self.text.editable=isEditable;
}

-(BOOL)isEditable
{
    return self.text.isEditable;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(NSDragOperation)browser:(NSBrowser *)browser validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger *)row column:(NSInteger *)column dropOperation:(NSBrowserDropOperation *)dropOperation
{
    return NSDragOperationCopy;
}

-(void)replaceLogMessage:(NSString*)msg color:(NSColor*)aColor
{
    [self.errorView setString:msg];
    [self.errorView setTextColor:aColor range:NSMakeRange(0, msg.length)];

}

-(void)reportError:(NSString*)error{
    
    [self replaceLogMessage:error color:[NSColor redColor]];
    NSLog(@"error view storage: %@ error: %@",self.errorView.textStorage,error);
}

-(void)reportMessage:(NSString*)message{
    [self replaceLogMessage:message color:[NSColor blackColor]];
    NSLog(@"error view storage: %@ message: %@",self.errorView.textStorage,message);
}

-(void)dealloc
{
    [_browser release];
    NSLog(@"deallocating MPWFileBrowser: %p",self);
    [super dealloc];
}

-(IBAction)showNewClassDialogue:(id)sender
{
    [self.newClassName.window makeKeyAndOrderFront:nil];
}

-(IBAction)defineClass:(id)sender
{
    NSString *className = [self.newClassName stringValue];
    NSString *fileName = [className stringByAppendingPathExtension:@"st"];
    NSString *template = [NSString stringWithFormat:@"class %@ {\n}\n",className];
    id <MPWHierarchicalStorage> store = [self.browser.store source];
    NSLog(@"filename: %@",fileName);
    NSLog(@"template: %@",template);
    NSLog(@"store before: %@ / %@",store,[store childrenOfReference:@"/"]);
    id ref = [MPWGenericIdentifier referenceWithPath:fileName];
    [store at:ref put:template];
    NSLog(@"Source before: %@ %@",[store source],[[store source] childrenOfReference:@"/"]);
    [[store source] at:ref put:template];        //  FIXME:  workaround for caching stores not being able to merge source and cache refs
    NSLog(@"Source after: %@ %@",[store source],[[store source] childrenOfReference:@"/"]);
    NSLog(@"store after: %@ / %@",store,[store childrenOfReference:@"/"]);
    [self.newClassName.window orderOut:nil];
    [self.browser reloadColumn:0];
}

-(IBAction)delete:(id)sender
{
    [self.browser.store deleteAt:[[self currrentBinding] identifier]];
    [[[self.browser.store source] source] deleteAt:[[self currrentBinding] identifier]];
    [self.browser reloadColumn:0];
}

@end
