//
//  MPWPOSTProcessor.h
//  ObjectiveHTTPD -> MPWFoundation
//
//  Created by Marcel Weiher on 1/22/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWPOSTProcessor : NSObject
{
	NSMutableDictionary *values;
	NSMutableDictionary *filenames;
	NSMutableDictionary *contentTypes;
	id lastKey;
	void *processor;
}


+processor;
-(void)appendBytes:(const void*)bytes length:(int)len toKey:(NSString*)key filename:(NSString*)filename contentType:(NSString*)contentType;

-(void)addParameters:(NSDictionary*)additionalParameters;

-(void*)processor;
-(void)setProcessor:(void*)newProcessor;

-(NSMutableDictionary*)values;
@end

