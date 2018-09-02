//
//  MPWMessageFilterStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/15/12.
//
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWMessageFilterStream : MPWFilter
{
    SEL     selector;
}

scalarAccessor_h(SEL, selector, setSelector )
+(instancetype)streamWithSelector:(SEL)newSelector;

@end
