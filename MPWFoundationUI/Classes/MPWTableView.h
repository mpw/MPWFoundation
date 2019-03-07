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
@property (readonly)          id <MPWReferencing> currentReference;

- selectedObject;
- objectAtRow:(NSUInteger)row;

- (CGFloat)calculateHeightForRow:(NSUInteger)row usingColumn:(NSString *)columnName;

@end
