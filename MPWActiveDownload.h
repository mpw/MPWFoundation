//
//  MPWActiveDownload.h
//  Elaph
//
//  Created by Marcel Weiher on 12/28/10.
//  Copyright 2010-2011 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWResourceLoadRequest,MPWByteStream,MPWCachingDownloader;

@interface MPWActiveDownload : NSObject {
	id	downloader;
	MPWResourceLoadRequest*	request;
	NSURLConnection *urlConnection;
	MPWByteStream   *output;
	long long		downloadedSoFar;
	long long		downloadSize;
	BOOL	done;
	BOOL	log;
	BOOL	requestStarted;
}

-(float)percentDone;
-(BOOL)done;
-(id)initWithRequest:(MPWResourceLoadRequest*)newRequest downloader:(MPWCachingDownloader*)newDownloader;
-(id)initWithRequest:(MPWResourceLoadRequest*)newRequest downloadingToPath:(NSString*)targetPath;
-(BOOL)isRunning;


@end
