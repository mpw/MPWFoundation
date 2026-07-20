//
//  MPWUIKitBoundControls.m
//  MPWFoundationUIKit
//

#import "MPWUIKitBoundControls.h"

#pragma mark - uniform value access

static NSString *MPWStringValue(id value)
{
    return (value == nil || value == (id)[NSNull null]) ? @"" : [value description];
}

// Defaults: a plain view has no value and ignores edits.  The categories below
// override the parts that apply; category dispatch picks the most specific one.
@implementation UIView (MPWObjectValue)
- (id)objectValue { return nil; }
- (void)setObjectValue:(id)objectValue { }
- (void)setValueEditable:(BOOL)editable { }
@end

@implementation UIControl (MPWObjectValue)
- (void)setValueEditable:(BOOL)editable { self.enabled = editable; }
@end

@implementation UILabel (MPWObjectValue)
- (id)objectValue { return self.text; }
- (void)setObjectValue:(id)objectValue { self.text = MPWStringValue(objectValue); }
@end

@implementation UITextField (MPWObjectValue)
- (id)objectValue { return self.text ?: @""; }
- (void)setObjectValue:(id)objectValue { self.text = MPWStringValue(objectValue); }
@end

@implementation UITextView (MPWObjectValue)
- (id)objectValue { return self.text ?: @""; }
- (void)setObjectValue:(id)objectValue { self.text = MPWStringValue(objectValue); }
- (void)setValueEditable:(BOOL)editable { self.editable = editable; }
@end

@implementation UISwitch (MPWObjectValue)
- (id)objectValue { return @(self.isOn); }
- (void)setObjectValue:(id)objectValue { self.on = [objectValue boolValue]; }
@end

@implementation UIDatePicker (MPWObjectValue)
- (id)objectValue { return self.date; }
- (void)setObjectValue:(id)objectValue { if ([objectValue isKindOfClass:[NSDate class]]) { self.date = objectValue; } }
@end

@implementation UISegmentedControl (MPWObjectValue)
- (id)objectValue { return @(self.selectedSegmentIndex); }
- (void)setObjectValue:(id)objectValue { self.selectedSegmentIndex = [objectValue integerValue]; }
@end

@implementation UISlider (MPWObjectValue)
- (id)objectValue { return @(self.value); }
- (void)setObjectValue:(id)objectValue { self.value = [objectValue floatValue]; }
@end

@implementation UIStepper (MPWObjectValue)
- (id)objectValue { return @(self.value); }
- (void)setObjectValue:(id)objectValue { self.value = [objectValue doubleValue]; }
@end


#pragma mark - bound controls

// Shared binding behaviour, expressed once in terms of the MPWObjectValue
// protocol above, so each subclass only has to say how it reports edits.
#define MPW_BOUND_CONTROL_IMPL(cls, connect)                                    \
@implementation cls                                                             \
- (void)mpw_installNotifications { [self installProtocolNotifications]; }        \
- (void)setBinding:(MPWReference *)newBinding                                   \
{                                                                               \
    self.ref = newBinding;                                                      \
    connect;                                                                    \
    [self mpw_installNotifications];                                            \
    [self updateFromRef];                                                       \
}                                                                               \
- (void)updateFromRef                                                           \
{                                                                               \
    if (self.ref) { [self setObjectValue:self.ref.value]; }                      \
    if (self.enabledRef) { [self setValueEditable:[self.enabledRef.value boolValue]]; } \
}                                                                               \
- (void)updateToRef { if (self.ref) { self.ref.value = [self objectValue]; } }   \
- (void)modelDidChange:(NSNotification *)notification { [self updateFromRef]; }  \
- (void)dealloc { [_ref release]; [_enabledRef release]; [super dealloc]; }      \
@end

#define MPW_CONNECT_VALUE_CHANGED \
    [self addTarget:self action:@selector(updateToRef) forControlEvents:UIControlEventValueChanged]
#define MPW_CONNECT_END_EDITING \
    [self addTarget:self action:@selector(updateToRef) forControlEvents:UIControlEventEditingDidEnd]; \
    [self addTarget:self action:@selector(updateToRef) forControlEvents:UIControlEventEditingDidEndOnExit]
#define MPW_CONNECT_NONE do { } while (0)

MPW_BOUND_CONTROL_IMPL(MPWUITextField,        MPW_CONNECT_END_EDITING)
MPW_BOUND_CONTROL_IMPL(MPWUISwitch,           MPW_CONNECT_VALUE_CHANGED)
MPW_BOUND_CONTROL_IMPL(MPWUISegmentedControl, MPW_CONNECT_VALUE_CHANGED)
MPW_BOUND_CONTROL_IMPL(MPWUISlider,           MPW_CONNECT_VALUE_CHANGED)
MPW_BOUND_CONTROL_IMPL(MPWUIStepper,          MPW_CONNECT_VALUE_CHANGED)
MPW_BOUND_CONTROL_IMPL(MPWUIDatePicker,       MPW_CONNECT_VALUE_CHANGED)
MPW_BOUND_CONTROL_IMPL(MPWUILabel,            MPW_CONNECT_NONE)

// UITextView is not a UIControl, so it reports the end of editing by delegate.
@interface MPWUITextView () <UITextViewDelegate>
@end
MPW_BOUND_CONTROL_IMPL(MPWUITextView,         self.delegate = self)

@implementation MPWUITextView (editing)
- (void)textViewDidEndEditing:(UITextView *)textView { [self updateToRef]; }
@end


@implementation MPWUIEmailField

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.borderStyle = UITextBorderStyleBezel;
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.textContentType = UITextContentTypeEmailAddress;
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return self;
}

@end


@implementation MPWUIValueButton

- (void)setBinding:(MPWReference *)newBinding
{
    self.ref = newBinding;
    [self installProtocolNotifications];
    [self updateFromRef];
}

- (void)updateFromRef
{
    if (self.ref) { [self setObjectValue:self.ref.value]; }
    if (self.enabledRef) { [self setValueEditable:[self.enabledRef.value boolValue]]; }
}

- (void)updateToRef { if (self.ref) { self.ref.value = [self objectValue]; } }
- (void)modelDidChange:(NSNotification *)notification { [self updateFromRef]; }

// The button's value is a model value; its title is the matching display value.
- (id)objectValue { return self.representedValue; }

- (void)setObjectValue:(id)value
{
    self.representedValue = value;
    if (self.preservesConfiguredTitle &&
        (![value respondsToSelector:@selector(length)] || [value length] == 0)) { return; }
    NSString *title = MPWStringValue(value);
    NSUInteger mapped = [self.values indexOfObject:value ?: [NSNull null]];
    if (mapped != NSNotFound && mapped < self.displayValues.count) {
        title = [self.displayValues[mapped] description];
    }
    if (self.appendsDisclosureIndicator && title.length) { title = [title stringByAppendingString:@"  ›"]; }
    [self setTitle:title forState:UIControlStateNormal];
}

- (void)setValueEditable:(BOOL)editable { self.enabled = editable; }

- (void)installValueMenu
{
    if (!self.values.count) { return; }
    if (@available(iOS 14.0, *)) {
        NSMutableArray *actions = [NSMutableArray array];
        __unsafe_unretained MPWUIValueButton *button = self;
        NSArray *titles = self.displayValues ?: self.values;
        [self.values enumerateObjectsUsingBlock:^(id value, NSUInteger index, BOOL *stop) {
            NSString *title = index < titles.count ? [titles[index] description] : [value description];
            [actions addObject:[UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction *a) {
                // Choosing a value writes it back through the binding.
                [button setObjectValue:value];
                [button updateToRef];
                [button sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
            }]];
        }];
        self.menu = [UIMenu menuWithTitle:@"" children:actions];
        self.showsMenuAsPrimaryAction = YES;
    }
}

- (void)dealloc
{
    [_ref release];
    [_enabledRef release];
    [_representedValue release];
    [_values release];
    [_displayValues release];
    [super dealloc];
}

@end
