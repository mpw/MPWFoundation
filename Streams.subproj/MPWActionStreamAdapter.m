//
//  MPWActionStreamAdapter.m
//  FlowChat
//
//  Created by Marcel Weiher on 2/13/17.
//  Copyright © 2017 metaobject. All rights reserved.
//
//  Adapt NSControls as senders
//

#import "MPWActionStreamAdapter.h"

@interface MPWStream(sender)
-(void)writeObject:(id)anObject sender:aSender;
@end


@interface NSObject(appkit)

-(void)setAction:(SEL)aSelector;
-(void)setDelegate:delegate;
-objectValue;

@end

@implementation MPWActionStreamAdapter

-initWithUIControl:aControl target:aTarget
{
    self=[super initWithTarget:aTarget];
    [aControl setTarget:self];
    [aControl setAction:@selector(getString:)];
    return self;
}

-initWithTextField:aControl target:aTarget
{
    self=[super initWithTarget:aTarget];
    [aControl setDelegate:self];
    return self;
}

-(void)getString:sender
{
    [self.target writeObject:[sender stringValue]];
}

- (void) controlTextDidChange: (NSNotification *)note {
    
    [self.target writeObject:[[note object] objectValue]];
}


@end
