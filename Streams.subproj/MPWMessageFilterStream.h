//
//  MPWMessageFilterStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/15/12.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWMessageFilterStream : MPWStream
{
    SEL     selector;
}

scalarAccessor_h(SEL, selector, setSelector )
+(instancetype)streamWithSelector:(SEL)newSelector;

@end
