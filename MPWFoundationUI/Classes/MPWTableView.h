//
//  MPWTableView.h
//  
//
//  Created by Marcel Weiher on 7.3.2019.
//

#import <Cocoa/Cocoa.h>
#import "ModelDidChangeNotification.h"

@protocol MPWStorage,MPWReferencing;
@class MPWBinding;

@interface MPWTableView : NSTableView <NSTableViewDataSource,ModelDidChange,NSTableViewDelegate>

@property (nonatomic, strong, nullable) MPWBinding *binding;
@property (nonatomic, strong, nullable) MPWBinding *cursorRef;
@property (nonatomic, strong, nullable) NSArray* (^valueFilter)(id object);

- selectedObject;
- objectAtRow:(NSUInteger)row;

-(CGFloat)calculateHeightForRow:(NSUInteger)row usingColumn:(NSString *)columnName;
-(NSArray *)unorderedObjects;


@end
