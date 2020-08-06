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

@end

@implementation MPWFileBrowser

-(instancetype)init
{
    return [self initWithNibName:@"MPWFileBrowser" bundle:[NSBundle bundleForClass:[self class]]];
}

-(IBAction)didSelect:(MPWBrowser*)sender
{
    NSLog(@"path: %@", [[[self.browser currentReference] asReference] path]);
    [self.text setString: [[[self.browser currentReference] value] stringValue]];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
