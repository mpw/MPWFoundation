//
//  MPWRESTCopyStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/5/18.
//

#import <MPWFoundation/MPWWriteStream.h>

@class MPWAbstractStore;

@interface MPWRESTCopyStream : MPWWriteStream

@property (nonatomic, strong) MPWAbstractStore *source,*target;

-initWithSource:(MPWAbstractStore*)newSource target:(MPWAbstractStore*)newTarget;

@end
