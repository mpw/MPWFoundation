//
//  MPWUIKitUIGenerator.m
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 20.06.26.
//

#import "MPWUIKitUIGenerator.h"
#import <UIKit/UIKit.h>


@implementation NSObject(AppKitUI)

-(void)generateUIKitUI:(MPWUIKitUIGenerator*)stream
{
    [self generateUI:stream];
}

@end


@implementation MPWUIKitUIGenerator


-(SEL)streamWriterMessage
{
    return @selector(generateUIKitUI:);
}



+(MPWTypeToObjectMapper*)defaultTypes2UIMapper
{
    MPWTypeToObjectMapper *type2view = [[MPWTypeToObjectMapper new] autorelease];
    type2view[@"bool"] = [UISwitch templateWithValues:@{ }];
    type2view[@"id"] = [UITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"Date"] = [UITextField templateWithValues:@{  @"borderStyle": @(UITextBorderStyleBezel) }];
    type2view[@"Text"] = [UITextView templateWithValues:@{ }];
    type2view[@"Horizontal"] = [UIStackView templateWithValues:@{ @"axis": @(UILayoutConstraintAxisHorizontal) }];
    type2view[@"Vertical"] = [UIStackView templateWithValues:@{ @"axis": @(UILayoutConstraintAxisVertical) }];
    return type2view;
}

-(void)endView
{
    self.target = (id)[(UIView*)(self.target) superview];
}


-(void)writeUIFormForStructVH:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [self beginView:self.type2view[@"Vertical"]];
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        [self beginView:self.type2view[@"Horizontal"]];
        if ( hasMoreThanOneField ) {
            [self writeObject:[[[UILabel alloc] initWithDictionary: @{ @"text": aField.title}] autorelease]];
        }
        [self writeObject:[self controlForType:aField.type]];
        [self endView];
    }
    [self writeObject:[UIView new]];
    [self endView];
}


-(void)writeUIFormForStructVV:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    for ( MPWVariableDefinition *aField in theStruct.fields) {
        [self writeObject:[[[UILabel alloc] initWithDictionary: @{ @"text": aField.title}] autorelease]];
        [self writeObject:[self controlForType:aField.type]];
    }
    [self writeObject:[UIView new]];
}

-(void)writeUIFormForStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    [self writeUIFormForStructVV:theStruct postAction:actionString];
}

+(id)defaultTarget
{
    return [[[UIStackView alloc] initWithDictionary:@{ @"axis": @(UILayoutConstraintAxisVertical) }] autorelease];
}

-(UIView*)rootView
{
    return (UIView*)self.target;
}

@end


@implementation UIView(streaming)

-(void)writeObject:aView
{
    [self addSubview:aView];
}

@end

@implementation UIStackView(streaming)

-(void)writeObject:aView
{
    [self addArrangedSubview:aView];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWUIKitUIGenerator(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
