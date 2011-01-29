//
//  MPWRusage.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 28/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "MPWObject.h"
#include <stdlib.h>
#ifdef LINUX
#include <linux/resource.h>
#endif


@interface MPWRusage : MPWObject
{
        struct rusage usage;
}

+current;
+timeRelativeTo:(MPWRusage*)start;
-(long)systemMicroseconds;
-(long)userMicroseconds;


@end

