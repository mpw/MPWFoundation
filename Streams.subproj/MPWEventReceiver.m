//
//  MPWEventReceiver.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 30.05.24.
//

#import "MPWEventReceiver.h"
#import "AccessorMacros.h"

@implementation MPWEventReceiver
{
    NSString *name;
}

-(void)registerWithNotificationCenter
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeObject:) name:name object:nil];
}

objectAccessor(NSString*, name, _setName)

-(void)setName:(NSString*)newName
{
    [self _setName:newName];
    [self registerWithNotificationCenter];
}

-initWithName:(NSString*)newName
{
    self=[super init];
    [self setName:newName];
    [self registerWithNotificationCenter];
    return self;
}

-(void)writeObject:(NSNotification*)notification
{
    [self.target writeObject:notification.object];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [name release];
    [_target release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWEventReceiver(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
