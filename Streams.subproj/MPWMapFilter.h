//
//  MPWMapFilter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/11/18.
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWMapFilter : MPWFilter

+(instancetype)filterWithSelector:(SEL)selector;
-(instancetype)initWithSelector:(SEL)selector;

+(instancetype)filterWithBlock:aBlock;
-(instancetype)initWithBlock:aBlock;


@end
