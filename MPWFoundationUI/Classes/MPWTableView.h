//
//  MPWTableView.h
//  
//
//  Created by Marcel Weiher on 7.3.2019.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundationUI/ModelDidChangeNotification.h>

@protocol MPWStorage,MPWIdentifying;
@class MPWReference;

@interface MPWTableView : NSTableView <NSTableViewDataSource,ModelDidChange,NSTableViewDelegate>

@property (nonatomic, strong, nullable) MPWReference *binding;
@property (nonatomic, strong, nullable) MPWArrayCursor *cursor;
@property (nonatomic, strong, nullable) NSArray* (^valueFilter)(id object);
@property (nonatomic, weak, nullable)  id <NSTableViewDelegate> mpwDelegate;

- selectedObject;
- objectAtRow:(NSUInteger)row;

-(CGFloat)calculateHeightForRow:(NSUInteger)row usingColumn:(NSString *)columnName;
-(NSArray *)unorderedObjects;


@end
