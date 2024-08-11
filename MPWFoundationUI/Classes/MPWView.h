//
//  MPWView.h
//  MusselWind
//
//  Created by Marcel Weiher on 11/19/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@protocol MPWDrawingContext;

@interface MPWView : NSView {
    id drawingBlock;
}


-(void)drawRect:(NSRect)rect onContext:(id <MPWDrawingContext>)context;

@property(nonatomic,retain) id drawingBlock;

@end
