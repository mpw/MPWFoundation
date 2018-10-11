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
    BOOL isDirectory=NO;
    BOOL exists=[self exists:aReference isDirectory:&isDirectory];
    if ( exists){
        if (isDirectory) {
            return [self directoryForReference:aReference];
        } else {
            return [self dataWithURL:[self fileURLForReference:aReference]];
        }
    }
    return nil;
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

-(BOOL)exists:(MPWGenericReference *)aReference isDirectory:(BOOL*)isDirectory
{
    BOOL    exists=NO;
    NSURL   *url=[self fileURLForReference:aReference];
    exists=[[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:isDirectory];
    return exists;

}

-(BOOL)isLeafReference:(MPWGenericReference *)aReference
{
    BOOL isDirectory = NO;
    BOOL exists=[self exists:aReference isDirectory:&isDirectory];
    return exists && !isDirectory;
}

-(NSArray*)childrenOfReference:(id <MPWReferencing>)aReference
{
    NSArray *childNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aReference path] error:nil];
    return (NSArray*)[[MPWGenericReference collect] referenceWithPath:[childNames each]];
}


@end
