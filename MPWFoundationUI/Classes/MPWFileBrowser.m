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

-(void)awakeFromNib
{
    [super awakeFromNib];
    NSTextView *text=self.text;

    [text setAutomaticQuoteSubstitutionEnabled:NO];
    [text setAutomaticLinkDetectionEnabled:NO];
    [text setAutomaticDataDetectionEnabled:NO];
    [text setAutomaticDashSubstitutionEnabled:NO];
    [text setAutomaticTextReplacementEnabled:NO];
    [text setAutomaticSpellingCorrectionEnabled:NO];
//    [text setFont:[NSFont fontWithName:@"Menlo Regular" size:11]];

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
