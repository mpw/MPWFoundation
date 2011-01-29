//
//  MPWFloat.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 20/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWNumber.h>


@interface MPWFloat : MPWNumber {
    @public
    double floatValue;

}

+float:(float)newValue;
-(double)doubleValue;


@end

typedef id   (*FIMP)(id, SEL, float );
typedef id   (*DIMP)(id, SEL, double );
