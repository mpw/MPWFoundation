//
//  MPWObjectReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on Sun Jan 18 2004.
/*  
    Copyright (c) 2004-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import "MPWObject.h"

@interface MPWObjectReference : MPWObject <NSCopying>{
	id  targetObject;
}

+objectReferenceWithTargetObject:anObject;
-initWithTargetObject:anObject;
-targetObject;
-referencedValue;

@end
