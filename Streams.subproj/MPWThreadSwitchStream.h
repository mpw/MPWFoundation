//
//  MPWThreadSwitchStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWThreadSwitchStream : MPWStream
{
    NSThread *targetThread;
}

@end
