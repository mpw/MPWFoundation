//
//  STTextField.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 27.02.21.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>

@protocol ModelDidChange;
NS_ASSUME_NONNULL_BEGIN

@interface STTextField : NSTextField<ModelDidChange,ValidationDidChange,SelectionDidChange>

@property (nonatomic, strong)  MPWReference *ref;
@property (nonatomic, strong)  MPWReference *enabledRef;
@property (nonatomic, assign)  BOOL inProcessing;

@end

NS_ASSUME_NONNULL_END
