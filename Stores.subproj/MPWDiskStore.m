//
//  MPWDiskStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDiskStore.h"
#import "MPWGenericReference.h"
#import "MPWGenericReference.h"
#import "MPWDirectoryBinding.h"
#import "NSStringAdditions.h"
#import "NSObjectFiltering.h"
#import "MPWByteStream.h"
#import "MPWDirectoryStore.h"

#include <unistd.h>

@implementation MPWDiskStore



-(NSURL*)fileURLForReference:(MPWGenericReference*)ref
{
    @try {
        NSURL *url =  [NSURL fileURLWithPath:[ref path]];              //  [ref URL] doesn't work
        return url;
    } @catch ( id e ) {
        NSLog(@"-[MPWDiskStore fileURLForReference:%@] exception: %@",ref,e);
    }
    return nil;
}

-(NSData*)dataWithURL:(NSURL*)url
{
    NSError *error=nil;
#ifdef GS_API_LATEST
    NSData *data=[NSData dataWithContentsOfURL:url];
    if (!data) {
        error=[NSError errorWithDomain:NSCocoaErrorDomain code:260 userInfo:@{}];
    }
#else
    NSData *data=[NSData dataWithContentsOfURL:url options:NSDataReadingMapped error:&error];
#endif
    if ( error ) {
        [self reportError:error];
    }
    return data;
}

-directoryForReference:(MPWGenericReference*)aReference
{
    NSArray *refs = (NSArray*)[[self collect] referenceForPath:[[self childNamesOfReference:aReference] each]];
    NSArray* combinedRefs = [[aReference collect] referenceByAppendingReference:[refs each]];
    return [[[MPWDirectoryBinding alloc] initWithContents:combinedRefs] autorelease];
}


-(NSData*)at:(MPWGenericReference*)aReference
{
    BOOL isDirectory=NO;
    BOOL exists=[self exists:aReference isDirectory:&isDirectory];
    if ( exists && isDirectory){
        return [self directoryForReference:aReference];
    } else {
        return [self dataWithURL:[self fileURLForReference:aReference]];
    }
    return nil;
}

-(void)at:(MPWGenericReference*)aReference put:(NSData*)theObject
{
    NSError *error=nil;
    BOOL success=NO;
    if ( theObject == nil ) {
        success=[[NSFileManager defaultManager] createDirectoryAtURL:[self fileURLForReference:aReference] withIntermediateDirectories:NO attributes:nil error:&error];
    } else {
        success=[theObject writeToURL:[self fileURLForReference:aReference] options:NSDataWritingAtomic error:&error];
    }
    if ( !success) {
        if (!error) {
            error=[NSError errorWithDomain:NSCocoaErrorDomain code:4 userInfo:@{}];
        }
        [self reportError:error];
    }
}

-(void)deleteAt:(MPWGenericReference*)aReference
{
    NSString *path = [[self fileURLForReference:aReference] path];
    unlink([path fileSystemRepresentation]);
}

-(BOOL)exists:(id <MPWReferencing>)aReference isDirectory:(BOOL*)isDirectory
{
    BOOL    exists=NO;
    NSURL   *url=[self fileURLForReference:aReference];
    exists=[[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:isDirectory];
    return exists;

}

-(id <Streaming>)writeStreamAt:(id <MPWReferencing>)aReference
{
    NSURL *url = [self fileURLForReference:aReference];
    NSString *path = [url path];
    return [MPWByteStream fileName:path];
}

-(void)at:(id <MPWReferencing>)aReference readToStream:(id <Streaming>)aStream
{
    [aStream writeObject:[self at:aReference]];
}

-(BOOL)hasChildren:(MPWGenericReference *)aReference
{
    BOOL isDirectory = NO;
    BOOL exists=[self exists:aReference isDirectory:&isDirectory];
    return exists && isDirectory;
}

-(NSArray*)childNamesOfReference:(id <MPWReferencing>)aReference
{
    NSError *error=nil;
    NSArray *childNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aReference path] error:&error];
    if (error) {
        [self reportError:error];
    }
    if ( childNames ) {
        childNames=[childNames sortedArrayUsingSelector:@selector(compare:)];  // FIXME: could use -sorted, but needs to be exposed in proper header
    } else {
        NSLog(@"no children for %@, error: %@",aReference,error);
    }
    return childNames;
}


//-(NSArray*)childrenOfReference:(id <MPWReferencing>)aReference
//{
//    NSArray *childNames = [self childNamesOfReference:aReference];;
//    return (NSArray*)[[self collect] referenceForPath:[childNames each]];
//}



@end

#import "DebugMacros.h"

@implementation MPWDiskStore(testing)

+(void)testGetErrorWhenTryingToWriteToNonExistentDirectory
{
    MPWDiskStore *d=[self store];
    NSArray *errors=[NSMutableArray array];
    d.errors = (NSObject<Streaming>*)errors;
    INTEXPECT(errors.count, 0, @"no errors before write attempt");
    d[[MPWGenericReference referenceWithPath:@"/tmp_doesnt_exist/hi"]] = [@"there" asData];
    INTEXPECT(errors.count, 1, @"should have gotten an error");
    NSError *error=errors.firstObject;
    INTEXPECT(error.code,NSFileNoSuchFileError,@"code should be file not found");
}

+(void)testGetErrorWhenTryingToReadToNonExistentFile
{
    MPWDiskStore *d=[self store];
    NSArray *errors=[NSMutableArray array];
    d.errors = (NSObject<Streaming>*)errors;
    INTEXPECT(errors.count, 0, @"no errors before write attempt");
    id result = d[[MPWGenericReference referenceWithPath:@"/tmp_doesnt_exist/doesnotexisteither"]];
    EXPECTNIL(result,@"should not get a result reading");
    INTEXPECT(errors.count, 1, @"should have gotten an error");
    NSError *error=errors.firstObject;
    INTEXPECT(error.code,NSFileReadNoSuchFileError,@"code should be no such file");
}

+testSelectors
{
    return @[
             @"testGetErrorWhenTryingToWriteToNonExistentDirectory",
             @"testGetErrorWhenTryingToReadToNonExistentFile",
             ];
}

@end
