//
//  MPWResourceLoadRequest.m
//  Elaph
//
//  Created by Marcel Weiher on 12/27/10.
//  Copyright 2010-2011 Marcel Weiher. All rights reserved.
//

#import "MPWResourceLoadRequest.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWCachingDownloader.h"

@implementation MPWResourceLoadRequest

objectAccessor( NSString, urlstring, setUrlstring )
scalarAccessor( SEL, selector, setSelector )
idAccessor( target, setTarget )
scalarAccessor( SEL, failureSelector, setFailureSelector )
scalarAccessor( SEL, progressSelector, setProgressSelector )

-initWithURLString:(NSString*)newUrlstring target:newTarget selector:(SEL)newSelector
{
	self=[super init];
	[self setTarget:newTarget];
	[self setSelector:newSelector];
	[self setUrlstring:newUrlstring];
	return self;
}

+requestWithURLString:(NSString*)newUrlstring target:newTarget selector:(SEL)newSelector
{
	return [[[self alloc] initWithURLString:newUrlstring target:newTarget selector:newSelector] autorelease];
}

-(void)deleteWithCache:(MPWCachingDownloader*) dataStore
{
	[dataStore deletaDataAtWebURL:[self urlstring]];
}


-(void)dealloc
{
	[target release];
	[urlstring release];
	[super dealloc];
}


@end
