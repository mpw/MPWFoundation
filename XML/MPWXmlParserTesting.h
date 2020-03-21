//
//  MPWXmlParserTesting.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 10/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWXmlParserTesting : NSObject {
	id					messages;
	BOOL				shouldAbort;
	NSMutableString		*totalText;
	NSCharacterSet		*nonWSCharSet;
	
}

@end
