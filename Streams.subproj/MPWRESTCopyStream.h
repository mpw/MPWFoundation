//
//  MPWRESTCopyStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/5/18.
//

#import <MPWFoundation/MPWWriteStream.h>

@class MPWAbstractStore;
@protocol MPWStorage;

@interface MPWRESTCopyStream : MPWWriteStream

@property (nonatomic, strong) id <MPWStorage> source,target;

-initWithSource:(id <MPWStorage>)newSource target:(id <MPWStorage>)newTarget;

@end
