//
//  STButton.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 04.09.23.
//

#import "STButton.h"

@implementation STButton

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self installProtocolNotifications];
    return self;
}



-(void)modelDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)validationDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)updateFromRef
{
//    NSLog(@"updating button %@ with ref: %@ value: %@",self,self.enabledRef,[self.enabledRef value]);
    if ( self.ref ) {
        self.state = [self.ref.value boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
    }
    if ( self.enabledRef ) {
        self.enabled = [self.enabledRef.value boolValue];
    }
}

// Value binding for toggle/checkbox buttons, mirroring the other ST controls:
// the button's on/off state is read from and written back to the store reference.
-(void)updateToRef
{
    if ( self.ref ) {
        self.ref.value = @(self.state == NSControlStateValueOn);
    }
}

-(void)setBinding:(MPWReference*)newBinding
{
    self.ref = newBinding;
    self.target = self;
    self.action = @selector(updateToRef);
}


@end
