//
//  MPWSFTPStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.22.
//

#import "MPWSFTPStore.h"
#import "MPWGenericReference.h"


@implementation MPWSFTPStore

-(BOOL)loadSSHFramework
{
    if ( !NSClassFromString(@"SSHConnection") ) {
        NSBundle *bundle = [NSBundle loadFramework:@"ObjectiveSSH"];
        return [bundle isLoaded];
    }
    return YES;
}

-(NSURL*)URLForReference:(id)aReference
{
    NSURL *connectionURL=[NSURL URLWithString:[aReference path]];
    return connectionURL;
}


-(NSObject <SSHConnection>*)connectionForURL:(NSURL*)connectionURL
{
    NSString *user=[connectionURL user];
    NSString *host=[connectionURL host];
    [self loadSSHFramework];
    NSObject <SSHConnection>* connection = [[NSClassFromString(@"SSHConnection") new] autorelease];
    connection.host=host;
    connection.user=user;
    return connection;
}

-(id <MPWStorage>)storeForURL:(NSURL*)connectionURL
{
    return [[self connectionForURL:connectionURL] store];
}

-(id<MPWStorage>)relativeStoreAt:(id <MPWReferencing>)reference
{
    NSURL *connectionURL=[self URLForReference:reference];
    NSString *relativePath = [connectionURL path];
    if ( [relativePath hasPrefix:@"/"]) {
        relativePath=[relativePath substringFromIndex:1];
    }
    MPWGenericReference *pathRef=[MPWGenericReference referenceWithPath:relativePath];
    return [(MPWAbstractStore*)[self storeForURL:connectionURL] relativeStoreAt:pathRef];
}



-(id)at:(id<MPWReferencing>)aReference
{
    NSURL *connectionURL=[self URLForReference:aReference];
    NSString *relativePath = [connectionURL path];
    if ( [relativePath hasPrefix:@"/"]) {
        relativePath=[relativePath substringFromIndex:1];
    }
    return [[self storeForURL:connectionURL] at:[MPWGenericReference referenceWithPath:relativePath]];
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    
}

@end
