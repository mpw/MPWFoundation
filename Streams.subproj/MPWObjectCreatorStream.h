//
//  MPWObjectCreatorStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 16/05/16.
//
//

#import <MPWFoundation/MPWFlattenStream.h>

@interface MPWObjectCreatorStream : MPWFlattenStream

-initWithClass:(Class)newTargetClass target:newTarget;
+streamWithClass:(Class)newTargetClass;


@end
