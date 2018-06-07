//
//  MPWDiskStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDiskStore.h"
#import "MPWReference.h"


@implementation MPWDiskStore

-(NSURL*)referenceToFileURL:(MPWReference*)ref
{
    return [ref URL];
}

-(NSData*)objectForReference:(MPWReference*)aReference
{
    return [NSData dataWithContentsOfURL:[self referenceToFileURL:aReference]];
}

-(void)setObject:(NSData*)theObject forReference:(MPWReference*)aReference
{
    [theObject writeToURL:[self referenceToFileURL:aReference] atomically:YES];
}

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    NSString *path = [[self referenceToFileURL:aReference] path];
    unlink([path fileSystemRepresentation]);
}

@end
