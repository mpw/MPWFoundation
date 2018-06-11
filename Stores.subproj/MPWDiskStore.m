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



-(NSURL*)referenceToFileURL:(MPWGenericReference*)ref
{
    return [NSURL fileURLWithPath:[ref path]];              //  [ref URL] doesn't work
}

-(NSData*)dataWithURL:(NSURL*)url
{
    return [NSData dataWithContentsOfURL:url];
}

-directoryForReference:(MPWGenericReference*)aReference
{
    return [self childrenOfReference:(MPWReference*)aReference];
}


-(NSData*)objectForReference:(MPWGenericReference*)aReference
{
    if ([self isLeafReference:(MPWReference*)aReference]) {
        return [self dataWithURL:[self referenceToFileURL:aReference]];
    } else {
        return [self directoryForReference:aReference];
    }
}

-(void)setObject:(NSData*)theObject forReference:(MPWGenericReference*)aReference
{
    [theObject writeToURL:[self referenceToFileURL:aReference] atomically:YES];
}

-(void)deleteObjectForReference:(MPWGenericReference*)aReference
{
    NSString *path = [[self referenceToFileURL:aReference] path];
    unlink([path fileSystemRepresentation]);
}

-(BOOL)isLeafReference:(MPWGenericReference *)aReference
{
    BOOL    isDirectory=NO;
    BOOL    exists=NO;
    exists=[[NSFileManager defaultManager] fileExistsAtPath:[aReference path] isDirectory:&isDirectory];
    return !isDirectory;
}

-(NSArray*)childrenOfReference:(MPWGenericReference*)aReference
{
    NSArray *childNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aReference path] error:nil];
    return (NSArray*)[[MPWGenericReference collect] referenceWithPath:[childNames each]];
}


@end
