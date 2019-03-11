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


-(NSArray*)listForItem:(id<MPWReferencing>)anItem
{
    BOOL root=NO;
//    NSLog(@"base reference: %@",anItem);
    if ( !anItem ) {
        anItem = [self.store referenceForPath:@"."];
        root=YES;
//    } else {
//        NSLog(@"non null base reference: %@",anItem);
    }
//    NSLog(@"base reference after normalizing: %@",anItem);
    NSArray *nameList = [self.store childrenOfReference:anItem];
//    NSLog(@"name list: %@",nameList);
    NSArray *refs= [[nameList collect] asReference];
//    NSLog(@"refs: %@",refs);
//    NSArray *refs= [[MPWGenericReference collect] referenceWithPath:[nameList each]];
    if (!root) {
//        anItem=[anItem referenceByAppendingReference:[MPWGenericReference referenceWithPath:[self showClassMethods] ? @"classMethods" : @"instanceMethods"]];
        refs= [[(NSObject*)anItem collect] referenceByAppendingReference:[refs each]];
    }
//    if ( !root) {
//        NSLog(@"refs after processing: %@",refs);
//    }
    return refs;

}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
    return [[self listForItem:item] count];
}


- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
    return [[self listForItem:item] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
    return ![self.store hasChildren:item];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
//    return [[item pathComponents] lastObject];
    if ( [self.browserDelegate respondsToSelector:_cmd] ) {
        return [self.browserDelegate browser:self objectValueForItem:(id)item];
    } else {
//        NSLog(@"path: %@ name: %@",item,[[item relativePathComponents] lastObject]);
        return [[item relativePathComponents] lastObject];
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
