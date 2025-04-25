//
//  MPWPOSTProcessor.m
//  ObjectiveHTTPD
//
//  Created by Marcel Weiher on 1/22/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWPOSTProcessor.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWPOSTProcessor

objectAccessor(NSMutableDictionary*,values, setValues )
objectAccessor(NSMutableDictionary*,filenames, setFilenames )
objectAccessor(NSMutableDictionary*,contentTypes, setContentTypes )
scalarAccessor( void*, processor, setProcessor )
scalarAccessor( id, lastKey, setLastKey )

-init
{
	self=[super init];
	[self setValues:[NSMutableDictionary dictionary]];
	[self setFilenames:[NSMutableDictionary dictionary]];
	[self setContentTypes:[NSMutableDictionary dictionary]];
	return self;
}

+processor {
	return [[[self alloc] init] autorelease];
}

-(void)appendBytes:(const void*)bytes length:(int)len toKey:(NSString*)key filename:(NSString*)filename contentType:(NSString*)contentType
{	
	NSMutableData *data=[[self values] objectForKey:key];
//    NSLog(@"appendBytes: %*s length: %d toKey: %@ filename: %@ contentType: %@",len,bytes,len,key,filename,contentType);
	if ( !data  ) {
#if 0
		if ( [self lastKey] != key ) {
			if ( [self lastKey] ) {
				NSLog(@"done with '%@' got %d bytes",[self lastKey],[[[self values] objectForKey:lastKey] length]);
			}
			[self setLastKey:key];
		}
		NSLog(@"start POST for '%@'->'%@'",key,filename);
#endif		
		data=[NSMutableData data];
		[[self values] setObject:data forKey:key];
	}
	[data appendBytes:bytes length:len];
	if ( ![[self filenames] objectForKey:key]  && filename) {
		[[self filenames] setObject:filename forKey:key];
	}
}

-(void)addParameters:(NSDictionary*)additionalParameters
{
	for ( NSString *key in [additionalParameters allKeys] ) {
		if ( ![[self values] objectForKey:key] ) {
			[[self values] setObject:[(NSString*)[additionalParameters objectForKey:key] dataUsingEncoding:NSISOLatin1StringEncoding] forKey:key];
		}
	}
}

-(void)dealloc
{
	[values release];
	[filenames release];
	[contentTypes release];
	[super dealloc];
}

-(NSString*)debugDescription
{
    return [NSString stringWithFormat:@"<%@:%p:  value: %@ filenames: %@ contentTypes: %@",
            [self class],self,values,filenames,contentTypes ];
}

-(NSString*)description
{
    NSMutableString *description=[NSMutableString string];
    if ( values.count) {
        [description appendString:@"values: "];
        for ( NSString *key in values.allKeys) {
            [description appendFormat:@" %@=%@",key,[values[key] stringValue]];
        }
    }
    if ( filenames.count) {
        [description appendString:@" filenames: "];
        for ( NSString *key in filenames.allKeys) {
            [description appendFormat:@" %@=%@",key,[filenames[key] stringValue]];
        }
    }
    return description;
}

@end


