//
//  CacheDirDataStore.h
//  LDMac
//
//  Created by Marcel Weiher on 9/15/10.
//  Copyright 2010-2011 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MPWDownloading <NSObject>

-(NSString*)pathForWebURL:(NSString*)webURL;
-(void)storeData:(NSData*)data withWebURL:(NSString*)webURLString;
-(NSData*)loadDataWithWebURL:(NSString*)webURLString;
-(BOOL)haveLocalDataForWebURL:(NSString*)webURLString;
-(void)deletaDataAtWebURL:(NSString*)webURLString;
-(NSData*)dataWithURLString:(NSString*)urlString;
-(NSData*)newestDataWithURLString:(NSString*)urlString;




@end


@interface MPWCachingDownloader : NSObject <MPWDownloading> {
	NSURL	 *baseURL;
	NSDictionary *cookies;
	NSString *cacheBaseDir;
	id	observer;
	BOOL writeCache,readCache;
	int _maxConcurrent;
}

-initWithBaseDirectory:(NSString*)newBaseDirectory;
-observer;
-(void)setObserver:newObserver;
-(void)downloadRequests:(NSArray*)requests;
-(void)downloadOnlyRequests:(NSArray*)requestArray;
-(void)setCookies:(NSDictionary*)newCookies;
-(void)setBaseURL:(NSURL*)newBaseURL;

@end
