//
//  MPWURLReference.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 20.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFileReference.h>


@interface MPWURLReference : MPWFileReference {
	NSError	*error;
    BOOL inPOST;
    
    NSMutableData *responseData;
}

-stream;
-lines;
-linesAfter:(int)numToSkip;


@end
