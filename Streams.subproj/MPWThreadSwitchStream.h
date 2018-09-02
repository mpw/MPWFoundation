//
//  MPWThreadSwitchStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWThreadSwitchStream : MPWFilter
{
    NSThread *targetThread;
}

@end
