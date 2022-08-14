//
//  MPWSoftPointerProxy.h
//  MPWFoundation
//
//  Created by Marcel Weiher on Wed Oct 01 2003.
/*  
    Copyright (c) 2003-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>
//#import <MPWFoundation/MPWKVCSoftPointer.h>

@class MPWKVCSoftPointer;

@interface MPWSoftPointerProxy : NSProxy {
	MPWKVCSoftPointer*	xxxsoftPointer;
}


objectAccessor_h(MPWKVCSoftPointer*, xxxsoftPointer, xxxsetSoftPointer )
+proxyWithSoftPointer:softPointer;
-initWithSoftPointer:softPointer;

@end


@interface NSObject(proxyForKeyPath)

-proxyForKeyPath:(NSString*)keyPath;

@end
