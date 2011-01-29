//
//  MPWInteger.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 20/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWNumber.h>


@interface MPWInteger : MPWNumber {
    @public
    int	intValue;
}

+integer:(int)newInt;
-initWithInteger:(int)newInt;


@end
