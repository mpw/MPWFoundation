//
//  SSHCommandStore.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 24.07.22.
//

#import "SSHCommandStore.h"
#import "SSHCommandStream.h"
#import "SSHCommandBinding.h"


@interface SSHCommandStore()

@property (nonatomic, strong) SSHConnection *connection;

@end

@implementation SSHCommandStore

-initWithConnection:aConnection
{
    self=[super init];
    self.connection = aConnection;
    return self;
}

-(SSHCommandBinding *)bindingForReference:(id)aReference inContext:(id)aContext
{
    SSHCommandBinding *binding = [SSHCommandBinding bindingWithReference:aReference inStore:self];
    binding.connection = self.connection;
    return binding;
}

-(id)at:(id<MPWReferencing>)aReference
{
    SSHCommandBinding *binding = [self bindingForReference:aReference inContext:nil];
    return [binding value];
}


@end
