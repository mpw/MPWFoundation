//
//  MPWBrowser.h
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 06.03.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MPWStorage,MPWHierarchicalStorage,MPWIdentifying;

@interface MPWBrowser : NSBrowser

+(instancetype)on:aStore;

@property (nonatomic, strong) id <MPWHierarchicalStorage> store;
@property (readonly)          id <MPWIdentifying> currentReference;
@property (nonatomic, strong) id <MPWIdentifying> rootReference;
@property (readonly)          id <MPWIdentifying> defaultRootReference;
@property (nonatomic, weak)   IBOutlet id browserDelegate;

-(IBAction)dumpGraphivViz:sender;

@end

NS_ASSUME_NONNULL_END
