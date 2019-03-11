//
//  MPWDiskStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDiskStore.h"
#import "MPWGenericReference.h"
#import "NSObjectFiltering.h"
#import "NSStringAdditions.h"
#include <unistd.h>

@implementation MPWDiskStore



-(NSURL*)fileURLForReference:(MPWGenericReference*)ref
{
    return [NSURL fileURLWithPath:[ref path]];              //  [ref URL] doesn't work
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
    return [self childrenOfReference:aReference];
}


-(NSData*)objectForReference:(MPWGenericReference*)aReference
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

-(void)setObject:(NSData*)theObject forReference:(MPWGenericReference*)aReference
{
    NSError *error=nil;
    BOOL success=[theObject writeToURL:[self fileURLForReference:aReference] options:NSDataWritingAtomic error:&error];
    if ( !success) {
        if (!error) {
            error=[NSError errorWithDomain:NSCocoaErrorDomain code:4 userInfo:@{}];
        }
        [self reportError:error];
    }
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
    NSError *error=nil;
    NSArray *childNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aReference path] error:&error];
    [self reportError:error];
    return (NSArray*)[[MPWGenericReference collect] referenceWithPath:[childNames each]];
}


-(BOOL)hasChildren:(id <MPWReferencing>)aReference
{
    return ![self isLeafReference:aReference];
}

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
