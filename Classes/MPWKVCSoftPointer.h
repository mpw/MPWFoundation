//
//  MPWKVCSoftPointer.h
//  MPWFoundation
//
//  Created by Marcel Weiher on Wed Oct 01 2003.
/*  
    Copyright (c) 2003-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import <MPWFoundation/MPWObject.h>
#import <MPWFoundation/AccessorMacros.h>

@interface MPWKVCSoftPointer : MPWObject {
	id	targetOrigin;
	id	kvcPath;
}

idAccessor_h( targetOrigin, setTargetOrigin )
idAccessor_h( kvcPath, setKvcPath )
-target;

@end

@interface NSObject(kvcSoftPointer)

-softPointerForKeyPath:(NSString*)keyPath;

@end
