//
//  MPWResourceLoadRequest.h
//  Elaph
//
//  Created by Marcel Weiher on 12/27/10.
//  Copyright 2010-2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>

@class MPWCachingDownloader;

@interface MPWResourceLoadRequest : NSObject {
	id	target;
	SEL selector;
	SEL failureSelector;
	SEL progressSelector;
	NSString *urlstring;
}

-initWithURLString:(NSString*)urlstring target:newTarget selector:(SEL)newSelector;
+requestWithURLString:(NSString*)newUrlstring target:newTarget selector:(SEL)newSelector;
-(NSString*)urlstring;
-target;
-(SEL)selector;

scalarAccessor_h( SEL, failureSelector, setFailureSelector )
scalarAccessor_h( SEL, progressSelector, setProgressSelector )

@end
