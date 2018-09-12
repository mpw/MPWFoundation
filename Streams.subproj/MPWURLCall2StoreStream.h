//
//  MPWURLCall2StoreStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/29/18.
//

#import <MPWFoundation/MPWFilter.h>

@protocol MPWStorage;

@interface MPWURLCall2StoreStream : MPWFilter

-(instancetype)initWithStore:(NSObject <MPWStorage>*)newStore;

@property (nonatomic, strong) NSObject <MPWStorage> *store;

@end
