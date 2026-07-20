//
//  MPWUIKitBoundControls.h
//  MPWFoundationUIKit
//
//  UIKit counterparts of the ST* controls in MPWFoundationUI: controls that
//  hold an MPWReference into a storage combinator and keep themselves in sync
//  with it.  Two layers:
//
//    1. MPWObjectValue — uniform objectValue/setObjectValue: access, added to
//       the stock UIKit classes by category, so binding code never branches on
//       control class (mirrors AppKit's NSControl objectValue).
//    2. MPWUI* subclasses — add `ref`/`enabledRef` plus updateFromRef/
//       updateToRef/setBinding:, exactly like STTextField & friends.
//

#import <UIKit/UIKit.h>
#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Uniform value access for presented controls.  value/setValue: would collide
/// with KVC and with MPWReference, so this mirrors AppKit's objectValue pair.
@protocol MPWObjectValue <NSObject>
- (nullable id)objectValue;
- (void)setObjectValue:(nullable id)objectValue;
- (void)setValueEditable:(BOOL)editable;
@end

@interface UIView (MPWObjectValue) <MPWObjectValue>
@end

/// A control bound to a value in a store through a reference it holds.
@protocol MPWBoundControl <MPWObjectValue>
@property (nonatomic, strong, nullable) MPWReference *ref;
@property (nonatomic, strong, nullable) MPWReference *enabledRef;
- (void)setBinding:(nullable MPWReference *)binding;
- (void)updateFromRef;
- (void)updateToRef;
@end

#define MPW_BOUND_CONTROL_INTERFACE(cls, superclass)                    \
@interface cls : superclass <MPWBoundControl, ModelDidChange>           \
@property (nonatomic, strong, nullable) MPWReference *ref;              \
@property (nonatomic, strong, nullable) MPWReference *enabledRef;       \
@end

MPW_BOUND_CONTROL_INTERFACE(MPWUITextField,        UITextField)
MPW_BOUND_CONTROL_INTERFACE(MPWUITextView,         UITextView)
MPW_BOUND_CONTROL_INTERFACE(MPWUISwitch,           UISwitch)
MPW_BOUND_CONTROL_INTERFACE(MPWUISegmentedControl, UISegmentedControl)
MPW_BOUND_CONTROL_INTERFACE(MPWUISlider,           UISlider)
MPW_BOUND_CONTROL_INTERFACE(MPWUIStepper,          UIStepper)
MPW_BOUND_CONTROL_INTERFACE(MPWUIDatePicker,       UIDatePicker)
MPW_BOUND_CONTROL_INTERFACE(MPWUILabel,            UILabel)

/// Email-flavoured text field; the template mechanism can't KVC-set keyboardType.
@interface MPWUIEmailField : MPWUITextField
@end

/// A button that stands for a value: a menu / disclosure row or a plain action.
/// `values` are the model values, `displayValues` their titles.
@interface MPWUIValueButton : UIButton <MPWBoundControl, ModelDidChange>

@property (nonatomic, strong, nullable) MPWReference *ref;
@property (nonatomic, strong, nullable) MPWReference *enabledRef;
/// The model value the button currently stands for (its objectValue).
@property (nonatomic, strong, nullable) id representedValue;
@property (nonatomic, strong, nullable) NSArray *values;
@property (nonatomic, strong, nullable) NSArray *displayValues;
@property (nonatomic, assign) BOOL appendsDisclosureIndicator;
@property (nonatomic, assign) BOOL preservesConfiguredTitle;

/// Build a UIMenu from `values`/`displayValues` that writes the chosen value.
- (void)installValueMenu;

@end

NS_ASSUME_NONNULL_END
