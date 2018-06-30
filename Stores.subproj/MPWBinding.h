//
//  MPWBinding.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@class MPWReference,MPWAbstractStore;
@protocol MPWReferencing;

@protocol MPWBinding

+(instancetype)bindingWithReference:aReference inStore:aStore;

@property (nonatomic, retain) id value;

-(void)delete;

// hierarchy support

-(BOOL)hasChildren;
-(NSURL*)URL;


@end



@interface MPWBinding : NSObject<MPWBinding>

@property (nonatomic, strong) id <MPWReferencing> reference;
@property (nonatomic, strong) MPWAbstractStore *store;


@end
