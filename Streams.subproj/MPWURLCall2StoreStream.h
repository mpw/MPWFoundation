//
//  MPWURLCall2StoreStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/29/18.
//

#import <MPWFoundation/MPWFoundation.h>

@protocol MPWStorage;

@interface MPWURLCall2StoreStream : MPWStream

@property (nonatomic, strong) NSObject <MPWStorage> *store;

@end
