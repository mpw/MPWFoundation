//
//  MPWResolvedReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@class MPWReference,MPWAbstractStore;

@protocol MPWBinding

-value;
-(void)setValue:newValue;
-(void)delete;

@end



@interface MPWBinding : NSObject<MPWBinding>

@property (nonatomic, strong) MPWReference *reference;
@property (nonatomic, strong) MPWAbstractStore *store;


@end
