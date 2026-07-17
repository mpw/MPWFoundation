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

+(void)testMapUIKitTypes
{
    MPWUIKitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];
    EXPECTTRUE( [[generator controlForType:types[@"id"]] isKindOfClass:[UITextField class]], @"default text field");
    EXPECTTRUE( [[generator controlForType:types[@"bool"]] isKindOfClass:[UISwitch class]], @"bool to checkbox");
}

+(void)testCreateForm
{
    MPWUIKitUIGenerator *generator=[self stream];
    MPWTypeStore *types=[MPWTypeStore store];
    
    MPWStructureDefinition *structure=[[[MPWStructureDefinition alloc] initWithName:@"todo" fields:@[
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Title" type:types[@"id"]] autorelease],
        [[[MPWInstanceVariableDefinition alloc] initWithName:@"Done" type:types[@"bool"]] autorelease],
    ]] autorelease];
    MPWForm *form=[[[MPWForm alloc] initWithDictionary:@{ @"def": structure, @"formAction": @"/newTask"}] autorelease];
    
    UIStackView *container = [generator process:form];
    EXPECTTRUE( [container isKindOfClass:[UIStackView class]],@"got the containing stack");
    INTEXPECT( [container axis], UILayoutConstraintAxisVertical,@"vertical");
//    UIView* formTopLevel = [container lastObject];
//    EXPECTTRUE( [formTopLevel isKindOfClass:[UIStackView class]],@"got the containing grid");
//    NSArray* formElements = [formTopLevel subviews];
//    INTEXPECT( formElements.count, 4, @"form elements");
//    EXPECTTRUE( [formElements[0] isKindOfClass:[UITextField class]], @"first label is a text field");
//    EXPECTTRUE( [formElements[1] isKindOfClass:[UITextField class]], @"first field is a text field");
//    EXPECTTRUE( [formElements[2] isKindOfClass:[UITextField class]], @"second label is a text field");
//    EXPECTTRUE( [formElements[3] isKindOfClass:[UIButton class]], @"second field is a (checkbox) button");
    
}

+(NSArray*)testSelectors
{
    return @[
        @"testCreateForm",
        @"testMapUIKitTypes",
    ];
}

@end
