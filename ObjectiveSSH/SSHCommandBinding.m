//
//  SSHCommandBinding.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 25.07.22.
//

#import "SSHCommandBinding.h"
#import "SSHCommandStream.h"

@implementation SSHCommandBinding

-(SSHCommandStream*)stream
{
    NSArray *components = [self.reference pathComponents];
    NSString *cmdAndArgs = [components componentsJoinedByString:@" "];
    SSHCommandStream *s=[[[SSHCommandStream alloc] initWithSSHConnection:self.connection command:cmdAndArgs] autorelease];
    [[self connection] openSSH];
    return s;
 }

-(NSData*)value
{
    SSHCommandStream *s=[self stream];
    NSMutableData *result=[NSMutableData data];
    s.target = [MPWByteStream streamWithTarget:result];
    [s run];
    return result;
}


@end
