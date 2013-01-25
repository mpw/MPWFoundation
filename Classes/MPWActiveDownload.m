//
//  MPWActiveDownload.m
//  Elaph
//
//  Created by Marcel Weiher on 12/28/10.
//  Copyright 2010-2012 Marcel Weiher. All rights reserved.
//

#import "MPWActiveDownload.h"
//#import <MPWFoundation/MPWFoundation.h>
#import "MPWResourceLoadRequest.h"
#import "MPWCachingDownloader.h"
#import "MPWByteStream.h"


@implementation MPWActiveDownload

objectAccessor( MPWResourceLoadRequest, request, setRequest )
objectAccessor( MPWByteStream, output, setOutput )
objectAccessor( MPWCachingDownloader, downloader, setDownloader )
objectAccessor( NSURLConnection, urlConnection, setUrlConnection )
boolAccessor( done, setDone )
boolAccessor( log, setLog )
intAccessor( downloadedSoFar, setDownloadedSoFar )
intAccessor( downloadSize, setDownloadeSize )

-(id)initWithRequest:(MPWResourceLoadRequest*)newRequest downloader:(MPWCachingDownloader*)newDownloader stream:(MPWByteStream*)target
{
	self=[super init];
	[self setOutput:target];
	[self setRequest:newRequest];
	[self setDownloader:newDownloader];
	[self setDone:NO];
	
	return self;
}

-(id)initWithRequest:(MPWResourceLoadRequest*)newRequest downloader:(MPWCachingDownloader*)newDownloader
{
	return [self initWithRequest:newRequest downloader:newDownloader stream:[MPWByteStream stream]];
}

-(id)initWithRequest:(MPWResourceLoadRequest*)newRequest downloadingToPath:(NSString*)targetPath
{
	return [self initWithRequest:newRequest downloader:nil stream:[MPWByteStream fileName:targetPath]];
}

-(BOOL)isRunning { return requestStarted; }

-(void)start
{
	if (!requestStarted ) {
		NSURLRequest *urlrequest = [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[[self request] urlstring]]] autorelease];
		[self setUrlConnection:[[[NSURLConnection alloc] initWithRequest:urlrequest delegate:self] autorelease]];
		requestStarted=YES;
	}
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if(log) NSLog(@"connection: %@ didReceiveResponse: %@", connection, response);
	if ( [response respondsToSelector:@selector(statusCode)] ) {
		if ( log ) {
					NSLog(@"statuscode: %ld for %@",(long)[(NSHTTPURLResponse*) response statusCode],[[self request] urlstring]);
		}
		if ( [(NSHTTPURLResponse*)response statusCode] == 404 ) {
			[connection cancel];
			done=YES;
		}
	}
//	if(selectorWhenRespondedWithResponse) [object performSelector:selectorWhenRespondedWithResponse withObject:response withObject:userData];
	downloadedSoFar=0;
	downloadSize=[response expectedContentLength];
//    [data setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	if(log) NSLog(@"connection: %@ didReceiveData: %lu", connection, (unsigned long)[d length]);
	if ( [request target] && [request progressSelector] ) {
		[[request target] performSelector:[request progressSelector]];
	}
	downloadedSoFar+=[d length];
	[output writeObject:d];
}

-(float)percentDone
{
	return  downloadSize > 0 ?  100.0 * downloadedSoFar / downloadSize : -1;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if(log) NSLog(@"connection: %@ didFailWithError: %@", connection, error);
	// should abort the stream 
	if ( [request target] && [request failureSelector] ) {
		[[request target] performSelector:[request failureSelector]];
	}
	done=YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if(log) NSLog(@"connectionDidFinishLoading: %@ stream: %@", connection,output);
	[output close];
	if ( [[output target] isKindOfClass:[NSData class]] ) {
		[downloader finishedLoading:request withData:[output target]];
	} else {
		[downloader finishedLoading:request withData:nil];	
	}
	done=YES;
	//    [connection release];
	//      [self release];
}

-(void)dealloc{
	[urlConnection release];
	[output release];
	[request release];
	[super dealloc];
}

@end
