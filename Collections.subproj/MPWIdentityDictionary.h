//
//  MPWIdentityDictionary.h
//  MPWFoundation
//
//  Created by Marcel Weiher on Sun Jan 18 2004.
/*  
    Copyright (c) 2004-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import <Foundation/Foundation.h>
#import <MPWObject.h>

@class MPWObjectCache;

@interface MPWIdentityDictionary : NSMutableDictionary {
	NSMutableDictionary* realDict;
	MPWObjectCache* cache;
}

-(NSInteger)uniqueIdForObject:anObject;
-(NSInteger)uniqueIdForObjectAddIfNecessary:anObject;

@end
