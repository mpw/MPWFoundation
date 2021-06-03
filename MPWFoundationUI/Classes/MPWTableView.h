//
//  MPWTableView.h
//  
//
//  Created by Marcel Weiher on 7.3.2019.
//

#import <Cocoa/Cocoa.h>

@protocol MPWStorage,MPWReferencing;

@interface MPWTableView : NSTableView <NSTableViewDataSource>

@property (nonatomic, strong) id <MPWStorage> store;
@property (nonatomic, strong) id <MPWReferencing> currentReference;

- selectedObject;
- objectAtRow:(NSUInteger)row;

- (CGFloat)calculateHeightForRow:(NSUInteger)row usingColumn:(NSString *)columnName;
-(NSArray *)unorderedObjects;


@end
