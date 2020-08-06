//
//  MPWFileBrowser.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 06.08.20.
//

#import <Cocoa/Cocoa.h>

@class MPWBrowser;
NS_ASSUME_NONNULL_BEGIN

@interface MPWFileBrowser : NSViewController

@property (nonatomic,strong) IBOutlet MPWBrowser *browser;
@property (nonatomic,strong) IBOutlet NSTextView *text;

-(IBAction)didSelect:sender;

@end

NS_ASSUME_NONNULL_END
