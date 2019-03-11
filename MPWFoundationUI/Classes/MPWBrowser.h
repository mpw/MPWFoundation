//
//  MPWBrowser.h
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 06.03.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MPWStorage,MPWReferencing;

@interface MPWBrowser : NSBrowser

@property (nonatomic, strong) id <MPWStorage> store;
@property (readonly)          id <MPWReferencing> currentReference;
@property (nonatomic, strong) id <MPWReferencing> rootReference;
@property (readonly)          id <MPWReferencing> defaultRootReference;
@property (nonatomic, weak)   IBOutlet id browserDelegate;

@end

NS_ASSUME_NONNULL_END
