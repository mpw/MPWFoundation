//
//  MPWView.m
//  MusselWind
//
//  Created by Marcel Weiher on 11/19/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//


#include "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import "MPWView_iOS.h"
#else
#import "MPWView.h"
#endif
#import <DrawingContext/MPWCGDrawingContext.h>

@implementation MPWView

@synthesize drawingBlock;

-(void)registerForMethodsDefined
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(methodsDefined) name:@"methodsDefined" object:nil];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self registerForMethodsDefined];
    }
    return self;
}

-(void)awakeFromNib
{
    [self registerForMethodsDefined];
}


-(void)drawOnContext:(id <MPWDrawingContext>)context
{
	// do nothing
}


-(void)drawRect:(NSRect)rect onContext:(id <MPWDrawingContext>)context
{
    if ( drawingBlock ) {
        ((DrawingBlock)drawingBlock)(context);
    }
    [self drawOnContext:context];
        
}

-(void)drawLayer:(CALayer*)layer inDrawingContext:(id <MPWDrawingContext>)context
{
	// do nothing
}

-(BOOL)logDrawRect
{
    return NO;
}

-(void)drawRect:(NSRect)rect
{
    if ([self logDrawRect] ) {
        NSLog(@"-[%@ drawRect:%@]",[self class],NSStringFromRect(rect));
    }
    MPWCGDrawingContext* context = [MPWCGDrawingContext currentContext];
#if TARGET_OS_IPHONE
    [context translate:0  :[self bounds].size.height];
    [[context scale:1  :-1] setlinewidth:1];
#endif
    //    NSLog(@"context: %@",context);
    @try {
        [self drawRect:rect onContext:context];
    } @catch ( id e ) {
        NSLog(@"exception while drawing");
    }
    if ([self logDrawRect] ) {
        NSLog(@"finished drawing");
    }
}


-(void)methodsDefined
{
    NSLog(@"new methods defined update display in MPWView");
    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}



-(void)drawLayer1:(CALayer*)layer inContext:(CGContextRef)cgContext
{
	MPWCGDrawingContext *context = [MPWCGDrawingContext contextWithCGContext:cgContext];
#if TARGET_OS_IPHONE
	[context translate:0  :[self bounds].size.height];
	[[context scale:1  :-1] setlinewidth:1];
#endif
    [self drawLayer:layer inDrawingContext:context];
}

-(void)dealloc
{
    [drawingBlock release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
