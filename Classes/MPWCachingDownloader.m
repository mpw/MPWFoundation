//
//  CacheDirDataStore.m
//  LDMac
//
//  Created by Marcel Weiher on 9/15/10.
//  Copyright 2010-2012 Marcel Weiher. All rights reserved.
//

#import "MPWCachingDownloader.h"
#import "NSStringAdditions.h"
#import "MPWResourceLoadRequest.h"
#import "MPWActiveDownload.h"
#import "NSObjectFiltering.h"

@implementation MPWCachingDownloader

objectAccessor( NSString, cacheBaseDir, setCacheBaseDir )
idAccessor( observer, setObserver )

-(void)refreshItemFromBackground:anItem
{
	[observer refreshItemFromBackground:anItem];
}

-initWithBaseDirectory:(NSString*)newBaseDirectory
{
	self=[super init];
	[self setCacheBaseDir:newBaseDirectory];
	return self;
}

-(NSString*)defaultBaseDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

-init
{
	return [self initWithBaseDirectory:[self defaultBaseDirectory]];
}

-(NSString*)pathForWebURL:(NSString*)webURL
{
	NSString *filename = [[webURL componentsSeparatedByString:@"/"] componentsJoinedByString:@"_"];
	NSString *path = [self cacheBaseDir];
	if ( path ) {
		BOOL pathIsDirectory = NO;
		if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&pathIsDirectory] && pathIsDirectory == NO) {
			[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}
	return [path stringByAppendingPathComponent:filename];
	
}

-(void)storeData:(NSData*)data withWebURL:(NSString*)webURLString
{
	NSString *localPath = [self pathForWebURL:webURLString];
	if ( localPath ) {
		if ( ![data writeToFile:localPath atomically:YES] ) {
			NSLog(@"error storing: %@ -- %@",webURLString,[self pathForWebURL:webURLString]);
		}
	}
}
-(NSData*)loadDataWithWebURL:(NSString*)webURLString
{
//	NSLog(@"fetch: %@ -> %@",webURLString,[self pathForWebURL:webURLString]);
	return [NSData dataWithContentsOfMappedFile:[self pathForWebURL:webURLString]];
}

-(BOOL)haveLocalDataForWebURL:(NSString*)webURLString
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self pathForWebURL:webURLString]];
}

-(NSData*)dataWithURLString:(NSString*)urlString
{
	NSData *value=nil;
	if ( [self haveLocalDataForWebURL:urlString] ) {
		value = [self loadDataWithWebURL:urlString];
	} else {
		value = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
		[self storeData:value withWebURL:urlString];
	}
	return value;
}

-(NSData*)newestDataWithURLString:(NSString*)urlString
{
	NSData *cached=nil;
	NSData *fromNet=nil;
	NSData *returnValue=nil;
	if ( [self haveLocalDataForWebURL:urlString] ) {
		cached = [self loadDataWithWebURL:urlString];
	}
	fromNet = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
	if ( fromNet == nil ) {
		returnValue=cached;
	} else 	{
		if (! [fromNet isEqualToData:cached] ) {
			[self storeData:fromNet withWebURL:urlString];
		}		
		returnValue=fromNet;
	}
	return returnValue;
}

-(void)deletaDataAtWebURL:(NSString*)webURLString
{
	NSError *error=nil;
	//	NSLog(@"delete: %@ -> %@",webURLString,[self pathForWebURL:webURLString]);
	//	NSLog(@"file exists before: %d",[self haveLocalDataForWebURL:webURLString]);
	if ( ![[NSFileManager defaultManager] removeItemAtPath:[self pathForWebURL:webURLString] error:&error] ) {
		NSLog(@"error deleting at %@ --  path: %@ : %@",webURLString,[self pathForWebURL:webURLString],error);
	}
	//	NSLog(@"file exists after: %d",[self haveLocalDataForWebURL:webURLString]);
}

-(void)notifyDone:request withData:data
{
	if ([request target]) {
		if ( [request selector] ) {
			[[request target] performSelector:[request selector] withObject:data];
		}
		[self refreshItemFromBackground:[request target]];
	}
}

-(void)finishedLoading:request withData:data
{
//	NSLog(@"storing %d bytes for %@ --  path: %@",[data length],[request urlstring],[self pathForWebURL:[request urlstring]]);
	if (data) {
		[self storeData:data withWebURL:[request urlstring]];
	}
	[self notifyDone:request withData:data];
}

-(void)downloadRequestSync:(MPWResourceLoadRequest*) request
{
	id pool=[NSAutoreleasePool new];
	NSData *data = [self dataWithURLString:[request urlstring]];
	[self notifyDone:request withData:data];
	[pool release];
}

-(MPWActiveDownload*)activeDownloadFromRequest:(MPWResourceLoadRequest*)request
{
	if ( [request target] ) {
		return [[[MPWActiveDownload alloc] initWithRequest:request downloader:self] autorelease];
	} else {
		return [[[MPWActiveDownload alloc] initWithRequest:request downloadingToPath:[self pathForWebURL:[request urlstring]]] autorelease];
	}
}

-(MPWActiveDownload*)handleRequestLocallyOrGenerateDownload:(MPWResourceLoadRequest*)request
{
	if ( [self haveLocalDataForWebURL:[request urlstring]] ) {
//		NSLog(@"have locally: %@ --  path: %@",[request urlstring],[self pathForWebURL:[request urlstring]]);
		if ( [request target] && [request selector] ) {
			[self notifyDone:request withData:[self loadDataWithWebURL:[request urlstring]]];
		}
		return nil;
	} else {
//		NSLog(@"need to request: %@ --  path: %@",[request urlstring],[self pathForWebURL:[request urlstring]]);
		@try {
			return [self activeDownloadFromRequest:request];
		} @catch (id e) {
		}
		return nil;
	}
}

-(int)reportDoneFromRequests:(NSMutableSet*)downloads into:(NSMutableSet*)doneSet
{
	int numDone=0;
    NSMutableSet *newDone=[NSMutableSet set];
	for ( MPWActiveDownload *download in downloads ) {
		if ( [download done] ) {
			[doneSet addObject:download];
            [newDone addObject:download];
			numDone++;
		}
	}
	[downloads minusSet:newDone];
	return numDone;
}

-(int)runRequests:(NSMutableSet*)downloads forSeconds:(NSTimeInterval)secondsToRun reportDone:(NSMutableSet*)doneSet
{
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:secondsToRun]];
	return [self reportDoneFromRequests:downloads into:doneSet];
}

-(int)runRequests:(NSMutableArray*)requests active:(NSMutableSet*)downloads forSeconds:(NSTimeInterval)secondsToRun reportDone:(NSMutableSet*)doneSet maxConcurrent:(int)maxConcurrent
{
	while ( [requests count] && [downloads count] < maxConcurrent ) {
		id dl=[requests objectAtIndex:0];
		[dl start];
		[downloads addObject:dl];
		[requests removeObjectAtIndex:0];
	}
	return [self runRequests:downloads forSeconds:secondsToRun reportDone:doneSet];
}

-(int)defaultMaxConcurrent
{
	return 10;
}

intAccessor( _maxConcurrent, setMaxConcurrent )

-(int)maxConcurrent
{
	int result=[self _maxConcurrent];
	if ( result <= 0 ) {
		result=[self defaultMaxConcurrent];
	}
	return MIN(result, 1000 );
}

-(void)runUntilAllRequestsDownloaded:(NSArray*)downloadsIn maxConcurrent:(int)maxConcurrent
{
	int numDone=0;
	NSMutableArray *requests = [NSMutableArray arrayWithArray:downloadsIn];
	NSMutableSet *active=[NSMutableSet set];
	NSMutableSet *done=[NSMutableSet set];
	while ( [requests count] + [active count] > 0 ) {
		numDone = [self runRequests:requests active:active forSeconds:0.001 reportDone:done maxConcurrent:maxConcurrent];
	}
}

-(void)runUntilAllRequestsDownloaded:(NSArray*)downloads
{
	[self runUntilAllRequestsDownloaded:downloads maxConcurrent:[self maxConcurrent]];
}


-(void)downloadRequests:(NSArray*)requests
{
	NSArray *downloads =(NSArray*)[[self collect] handleRequestLocallyOrGenerateDownload:[requests each]];
	[self runUntilAllRequestsDownloaded:downloads];
}


-(void)downloadOnlyRequests:(NSArray*)requestArray
{
	[[requestArray do] setTarget:nil];
	[self downloadRequests:requestArray];
}


-(void)downloadRequest:(MPWResourceLoadRequest*) request
{
	[self downloadRequests:[NSArray arrayWithObject:request]];
}
-(void)downloadOnlyRequest:(MPWResourceLoadRequest*) request
{
	[self downloadOnlyRequests:[NSArray arrayWithObject:request]];
}



DEALLOC(
        RELEASE(observer);
        RELEASE(cacheBaseDir);
)

@end

#import "DebugMacros.h"


@implementation MPWCachingDownloader(testing)

+_testRequest
{
	NSURL *url=[[NSBundle bundleForClass:self] URLForResource:@"ResourceTest" withExtension:@""];
	NSMutableArray *target=[NSMutableArray array];
	MPWResourceLoadRequest *r=[MPWResourceLoadRequest requestWithURLString:[url stringValue] target:target selector:@selector(addObject:)];
	return r;
}

+(void)testNoCacheDir
{
	MPWCachingDownloader *dl=[[[self alloc] initWithBaseDirectory:nil] autorelease];
	EXPECTFALSE( [dl haveLocalDataForWebURL:@"http://www.amazon.com"], @"no cache, no local files");
	EXPECTNIL( [dl pathForWebURL:@"http://www.amazon.com"], @"no local paths");
	MPWResourceLoadRequest *r=[self _testRequest];
	[dl downloadRequest:r];
	INTEXPECT( [[r target] count], 1, @"should have an item");
	IDEXPECT( [[[r target] lastObject] stringValue], @"This is a simple resource", @"resource content");
}

+(void)testWithCacheDir
{
	NSString *cacheDir=@"/tmp/CachingDownloaderTest";
	[[NSFileManager defaultManager] removeItemAtPath:cacheDir error:nil];
	[[NSFileManager defaultManager] createDirectoryAtPath:cacheDir
                              withIntermediateDirectories:YES attributes:nil error:nil   ];
	MPWCachingDownloader *dl=[[[self alloc] initWithBaseDirectory:cacheDir] autorelease];
	NSURL *url=[[NSBundle bundleForClass:self] URLForResource:@"ResourceTest" withExtension:@""];
	NSString *urlstring = [url stringValue];
	EXPECTNOTNIL( [dl pathForWebURL:urlstring], @"have local paths");
	EXPECTFALSE( [dl haveLocalDataForWebURL:urlstring], @"no cached data before load");
	EXPECTNIL( [dl loadDataWithWebURL:urlstring], @"and not getting any data, either");
	MPWResourceLoadRequest *r=[self _testRequest];
	[dl downloadRequest:r];
	INTEXPECT( [[r target] count], 1, @"should have an item");
	IDEXPECT( [[[r target] lastObject] stringValue], @"This is a simple resource", @"resource content");
	EXPECTTRUE( [dl haveLocalDataForWebURL:urlstring], @"have cached data after load");
	IDEXPECT( [[dl loadDataWithWebURL:urlstring] stringValue],  @"This is a simple resource", @"local fetch after cache succeds");
	[dl deletaDataAtWebURL:urlstring];
	EXPECTFALSE( [dl haveLocalDataForWebURL:urlstring], @"no cached data after delete");
	EXPECTNIL( [dl loadDataWithWebURL:urlstring], @"and not getting any data, either");
	
}

+(void)testNumDoneAndDoneArray
{
	MPWCachingDownloader *dl=[[[self alloc] initWithBaseDirectory:nil] autorelease];
	MPWResourceLoadRequest *r=[self _testRequest];
	NSMutableSet *downloads = [NSMutableSet setWithObject:[dl handleRequestLocallyOrGenerateDownload:r]];
	NSMutableSet *doneSet=[NSMutableSet set];
	int done = [dl runRequests:downloads forSeconds:0.001 reportDone:doneSet];
	INTEXPECT( done, 0, @"number of requests finished before actually starting downloads");
	INTEXPECT( [doneSet count], 0, @"same for finished array");
	[[downloads do] start];
	done = [dl runRequests:downloads forSeconds:0.005 reportDone:doneSet];
	INTEXPECT( done, 1, @"number of requests finished");
	INTEXPECT( [doneSet count], 1, @"finished request array");
	
}

+(void)testMoveCompletedDownloadsFromDownloadsToDone
{
	MPWCachingDownloader *dl=[[[self alloc] initWithBaseDirectory:nil] autorelease];
	MPWResourceLoadRequest *r=[self _testRequest];
	NSMutableSet *doneSet=[NSMutableSet set];
	NSMutableArray *downloadControl = [NSMutableArray array];
	NSMutableSet *downloads = [NSMutableSet set];
	for (int i=0;i<3;i++) {
		id download = [dl handleRequestLocallyOrGenerateDownload:r];
		[downloads addObject:download];
		[downloadControl addObject:download];
	}
	INTEXPECT( [downloads count], 3, @"make sure I have multiple downloads for single request, otherwise test doesn't work");
	int done;
	done = [dl runRequests:downloads forSeconds:0.001 reportDone:doneSet];
	INTEXPECT( done, 0, @"nothing done because I haven't started the downloads");
	INTEXPECT( [doneSet count], 0, @"nothing added to doneSet, again because the downloads haven't been started");
	[[downloadControl lastObject] start];
	done = [dl runRequests:downloads forSeconds:0.005 reportDone:doneSet];
	INTEXPECT( done, 1, @"activated one download, so should have gotten 1");
	INTEXPECT( [doneSet count], 1, @"should have 1 in done set ");
	INTEXPECT( [downloads count], 2, @"should have 1 fewer in downloads ");
	[downloadControl removeLastObject];
}

+(void)testLimitConcurrentDownloads
{
	MPWCachingDownloader *dl=[[[self alloc] initWithBaseDirectory:nil] autorelease];
	MPWResourceLoadRequest *r=[self _testRequest];
	NSMutableSet *doneSet=[NSMutableSet set];
	NSMutableArray *downloadControl = [NSMutableArray array];
	NSMutableSet *downloads = [NSMutableSet set];
	int done;
	for (int i=0;i<5;i++) {
		id download = [dl handleRequestLocallyOrGenerateDownload:r];
		[downloadControl addObject:download];
	}
	INTEXPECT( [downloadControl count], 5, @"make sure I have multiple downloads for single request, otherwise test doesn't work");
	MPWActiveDownload* firstDownload = [downloadControl objectAtIndex:0];
	MPWActiveDownload* secondDownload = [downloadControl objectAtIndex:1];
	EXPECTFALSE( [firstDownload isRunning], @"shouldn't have started yet");
	EXPECTFALSE( [secondDownload isRunning], @"shouldn't have started yet");
	done=[dl runRequests:downloadControl active:downloads forSeconds:0.00001 reportDone:doneSet maxConcurrent:2];
	EXPECTTRUE( [firstDownload isRunning], @"shouldn't have started yet");
	EXPECTTRUE( [secondDownload isRunning], @"shouldn't have started yet");
	INTEXPECT( done, 0, @"haven't started yet, so nothing done");
	INTEXPECT( [downloadControl count], 3, @"should have made 2 active, so 3 remain on request");
	INTEXPECT( [downloads count], 2, @"should have 2 active downloads" );
	EXPECTTRUE( [downloads containsObject:secondDownload], @"secondDownload should be one of the now active downloads");
	EXPECTTRUE( [downloads containsObject:firstDownload], @"firstDownload should be one of the now active downloads");
	done=[dl runRequests:downloadControl active:downloads forSeconds:0.001 reportDone:doneSet maxConcurrent:2];
	INTEXPECT( done, 2 , @"should have 2 done now");
	INTEXPECT( [downloadControl count], 3, @"but that didn't affect the input yet");
	done=[dl runRequests:downloadControl active:downloads forSeconds:0.01 reportDone:doneSet maxConcurrent:2];
	INTEXPECT( done, 2 , @"should have 2 done now");
	INTEXPECT( [downloadControl count], 1, @"moved from request to active");
	done=[dl runRequests:downloadControl active:downloads forSeconds:0.001 reportDone:doneSet maxConcurrent:2];
	INTEXPECT( [downloadControl count], 0, @"no more download requests left");
	INTEXPECT( [downloads count], 0 , @"no more active downloads" );
	INTEXPECT( [doneSet count], 5, @"all done");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testNoCacheDir",
//			@"testWithCacheDir",
			@"testNumDoneAndDoneArray",
			@"testMoveCompletedDownloadsFromDownloadsToDone",
//			@"testLimitConcurrentDownloads",
			nil];
}

@end

