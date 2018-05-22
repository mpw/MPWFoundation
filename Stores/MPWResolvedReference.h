//
//  MPWResolvedReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@class MPWReference,MPWAbstractStore;

@interface MPWResolvedReference : NSObject

@property (nonatomic, strong) MPWReference *reference;
@property (nonatomic, strong) MPWAbstractStore *store;

-value;
-setValue:newValue;
-(void)delete;

@end
