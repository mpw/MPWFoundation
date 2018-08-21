//
//  MPWDiskStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDiskStore.h"
#import "MPWGenericReference.h"
#import "NSObjectFiltering.h"

@implementation MPWDiskStore



-(NSURL*)fileURLForReference:(MPWGenericReference*)ref
{
    return [NSURL fileURLWithPath:[ref path]];              //  [ref URL] doesn't work
}

-(NSData*)dataWithURL:(NSURL*)url
{
    return [NSData dataWithContentsOfURL:url];
}

-directoryForReference:(MPWGenericReference*)aReference
{
    return [self childrenOfReference:aReference];
}


-(NSData*)objectForReference:(MPWGenericReference*)aReference
{
    if ([self isLeafReference:aReference]) {
        return [self dataWithURL:[self fileURLForReference:aReference]];
    } else {
        return [self directoryForReference:aReference];
    }
}

-(void)setObject:(NSData*)theObject forReference:(MPWGenericReference*)aReference
{
    [theObject writeToURL:[self fileURLForReference:aReference] atomically:YES];
}

-(void)deleteObjectForReference:(MPWGenericReference*)aReference
{
    NSString *path = [[self fileURLForReference:aReference] path];
    unlink([path fileSystemRepresentation]);
}

-(BOOL)isLeafReference:(MPWGenericReference *)aReference
{
    BOOL    isDirectory=NO;
    BOOL    exists=NO;
    NSURL   *url=[self fileURLForReference:aReference];
    exists=[[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
    return !isDirectory;
}

-(NSArray*)childrenOfReference:(id <MPWReferencing>)aReference
{
    NSArray *childNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aReference path] error:nil];
    return (NSArray*)[[MPWGenericReference collect] referenceWithPath:[childNames each]];
}


@end
