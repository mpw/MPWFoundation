//
//  MPWFileBrowser.h
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 06.08.20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWFileBrowser : NSViewController

@property (assign)                      BOOL     continuous;
@property (assign,getter=isEditable)    BOOL     editable;


@end

NS_ASSUME_NONNULL_END
