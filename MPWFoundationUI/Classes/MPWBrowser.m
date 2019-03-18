//
//  MPWBrowser.m
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 06.03.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import "MPWBrowser.h"
#import <MPWFoundation/MPWFoundation.h>



@implementation MPWBrowser

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self setInternalDelegate:self];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setInternalDelegate:self];
}

-internalDelegate
{
    return [super delegate];
}

-(void)setInternalDelegate:newDelegate
{
    [super setDelegate:newDelegate];
}

-(id<MPWReferencing>)defaultRootReference
{
    return [self.store referenceForPath:@"."];
}

-(id<MPWReferencing>)currentReference
{
    return [self itemAtIndexPath:[self selectionIndexPath]];
}

//  Remove

-(BOOL)showClassMethods
{
    return NO;
}

-(BOOL)isReferencingMethod:(id <MPWReferencing>)ref
{
    return [[ref relativePathComponents] count] > 2;
}

-(MPWBinding*)rootBinding
{
    id <MPWReferencing> ref = self.rootReference;
    if ( !ref ) {
        ref=self.defaultRootReference;
    }
    return [self.store bindingForReference:ref inContext:nil];
}

-(NSArray*)listForItem:(MPWBinding*)binding
{
    if ( !binding ) {
        binding = [self rootBinding];
    }
    return [binding children];
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
    return [[self listForItem:item] count];
}


- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
    return [[self listForItem:item] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(MPWBinding*)item
{
    return ![item hasChildren];
}

-(NSString*)objectValueForReference:(id <MPWReferencing>)item
{
    return [[item relativePathComponents] lastObject];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
    if ( [self.browserDelegate respondsToSelector:_cmd] ) {
        return [self.browserDelegate browser:self objectValueForItem:(id)item];
    } else {
        return [self objectValueForReference:item];
    }
}


@end

@implementation MPWBrowser(testing)

+(void)testBasicBrowsing
{
//    EXPECTTRUE(false, @"implemented");
}


+(NSArray*)testSelectors
{
    return @[
             @"testBasicBrowsing",
             ];
}

@end
