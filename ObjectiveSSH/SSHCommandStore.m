//
//  SSHCommandStore.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 24.07.22.
//

#import "SSHCommandStore.h"
#import "SSHCommandStream.h"

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


-(id)at:(id<MPWReferencing>)aReference
{
    NSArray *components = [aReference pathComponents];
    NSString *name=[components firstObject];
    NSArray *args = [components subarrayWithRange:NSMakeRange(1,components.count-1)];
    NSString *cmdAndArgs = [components componentsJoinedByString:@" "];
    SSHCommandStream *s=[[[SSHCommandStream alloc] initWithSSHSession:self.connection command:cmdAndArgs] autorelease];
    NSMutableData *result=[NSMutableData data];
    s.target = [MPWByteStream streamWithTarget:result];
    [s run];
    return result;
}


@end
