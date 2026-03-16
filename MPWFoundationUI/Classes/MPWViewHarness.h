//
//  MPWViewHarness.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 16.03.26.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWViewHarness : NSViewController

-(IBAction)triggerRedisplay:(id)sender;

@property (nonatomic, strong ) IBOutlet NSTextView *logView;
@property (nonatomic, strong ) IBOutlet NSView *slotForContentView;

@end

NS_ASSUME_NONNULL_END
