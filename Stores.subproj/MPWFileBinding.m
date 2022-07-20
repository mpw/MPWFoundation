//
//  MPWFileBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileBinding.h"
#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/MPWFoundation.h>
#import "MPWBytesToLines.h"
#import "MPWSkipFilter.h"

#import <unistd.h>

@interface NSObject (workspaceMBethods)

+sharedWorkspace;
-(void)openURL:(NSURL*)url;

@end

@implementation MPWFileBinding


-(NSTimeInterval)lastWritten
{
    return lastWritten;
}

-(NSTimeInterval)lastRead
{
    return lastRead;
}

-(BOOL)modifiedSinceLastWritten
{
    return [self lastModifiedTime] > [self lastWritten];
}

-(BOOL)modifiedSinceLastRead
{
    return [self lastModifiedTime] > [self lastRead];
}

-(BOOL)isEqual:(MPWFileBinding*)object
{
    return self.store == object.store &&
    [(NSObject*)(self.reference) isEqual:object.reference];
}

-(NSUInteger)hash
{
    return (NSUInteger)[(NSObject*)(self.reference) hash];
}

//-(void)startWatching
//{
//    [[self store] startWatching:self];
//}
//
//-(void)stopWatching
//{
//    
//}
//
//-(void)setDelegate:aDelegate
//{
//    [super setDelegate:aDelegate];
//    if ( aDelegate ) {
//        [self startWatching];
//    } else {
//        [self stopWatching];
//    }
//}



-(BOOL)existsAndIsDirectory:(BOOL*)isDirectory
{
	NSFileManager *manager=[NSFileManager defaultManager];
	BOOL exists = [manager fileExistsAtPath:[self path] isDirectory:isDirectory];;
    if (!exists) {
        *isDirectory=NO;
    }
    return exists;
}

-(BOOL)isBound
{
	return [self existsAndIsDirectory:NULL];;
}


-(NSDate *)lastModifiedDate
{
    NSDictionary *attributes=[[NSFileManager defaultManager] attributesOfItemAtPath:[self path] error:NULL];
    return attributes[NSFileModificationDate];
}

-(NSTimeInterval)lastModifiedTime
{
    return [[self lastModifiedDate] timeIntervalSinceReferenceDate];
}

-(BOOL)writeToURL:(NSURL*)targetURL atomically:(BOOL)atomically
{
    NSString *sourcePath=[self path];
    NSString *targetPath = [targetURL path];
    if ( sourcePath && targetPath ) {
        symlink([sourcePath fileSystemRepresentation], [targetPath fileSystemRepresentation]);
    }
    return YES;
}

-(NSString*)fancyPath
{
    if ( [self parentPath]) {
        long parentLength=[[self parentPath] length];
        if ( parentLength > 1 && ![[self parentPath] hasSuffix:@"/"]) {
            parentLength++;
        }
        return [[self path] substringFromIndex:parentLength];
    } else {
        return [[self path] lastPathComponent];
    }
}

-fileSystemValue
{
    return self;
}

-(id)value
{
//    NSLog(@"store: %@ ref: %@",self.store,self.reference);
    id value=[super value];
//    NSLog(@"value: %p, %@: %@",value,[value class],value);
    return value;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"file:%@",[self path]];
}

//-(void)mkdir          --- don't have -parent, so no sense to keep this
//{
//    if ( ![self isBound] ) {
//        [[self parent] mkdir];
//        [[NSFileManager defaultManager] createDirectoryAtPath:[self path] withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//}

-(void)open
{
    [[NSClassFromString(@"NSWorkspace") sharedWorkspace] openURL:[self URL]];
}

-(NSString*)urlPath
{
    return [(id)[self reference] urlPath];
}

-(MPWFDStreamSource*)source
{
    return [MPWFDStreamSource name:[self path]];
}

-stream
{
    return [self source];
}

-(MPWByteStream*)writeStream
{
    return [MPWByteStream fileName:[self path]];
}


-(MPWStreamSource*)lines
{
    MPWFDStreamSource *s=[self stream];
    [s setTarget:[MPWBytesToLines stream]];
    return s;
}

-(MPWStreamSource*)linesAfter:(int)numToSkip
{
    MPWStreamSource *stream=[self lines];
    MPWSkipFilter *skipper=[MPWSkipFilter stream];
    skipper.skip = numToSkip;
    [stream setFinalTarget:skipper];
    return stream;
}



-(void)dealloc
{
    [_parentPath release];
    [super dealloc];
}

@end

