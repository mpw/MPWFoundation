//
//  MPWForm.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.05.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStructureDefinition;
@protocol MPWStorage;

@interface MPWForm : NSObject

@property (nonatomic, strong) MPWStructureDefinition *def;
@property (nonatomic, strong) id <MPWStorage> store;
/// The values -resetForm: restores into store, keyed the same way as store.
@property (nonatomic, strong, nullable) id <MPWStorage> defaultStore;
@property (nonatomic, strong) NSString *formAction;
/// Title of the generated reset button, defaults to "Reset".
@property (nonatomic, strong) NSString *resetTitle;
/// Set hasResetAction to have the UI generator create a reset button wired to -resetForm:.
@property (nonatomic, assign) BOOL hasSubmitAction,hasResetAction;

-(IBAction)resetForm:(id)sender;
-(IBAction)submitForm:(id)sender;


@end

NS_ASSUME_NONNULL_END
