//
//  MPWFileBrowser.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 06.08.20.
//

#import "MPWFileBrowser.h"
#import "MPWBrowser.h"
#import <MPWFoundation/MPWFoundation.h>

@interface MPWFileBrowser ()

@property (nonatomic,strong)            IBOutlet MPWBrowser *browser;
@property (nonatomic,strong)            IBOutlet NSTextView *text;
-(IBAction)didSelect:sender;

@end

@implementation MPWFileBrowser

-(instancetype)init
{
    return [self initWithNibName:@"MPWFileBrowser" bundle:[NSBundle bundleForClass:[self class]]];
}

-(MPWBinding*)currrentBinding
{
    return (MPWBinding*)[self.browser currentReference];
}

-(IBAction)didSelect:(MPWBrowser*)sender
{
    [self.text setString: [[[self currrentBinding] value] stringValue]];
}

-(void)saveFileContents
{
    [[self currrentBinding] setValue:[[self.text string] asData]];
}

-(void)textDidChange:(NSNotification *)notification {
    if ( self.continuous ) {
        NSLog(@"save");
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

@end
