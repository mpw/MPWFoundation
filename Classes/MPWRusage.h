//
//  MPWRusage.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 28/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "MPWObject.h"
#include <stdlib.h>
#include <sys/resource.h>               // Linux


@interface MPWRusage : MPWObject
{
        struct rusage usage;
        long long absolute;
}

+current;
+timeRelativeTo:(MPWRusage*)start;
-(long)systemMicroseconds;
-(long)userMicroseconds;
-(int)absoluteMicroseconds;

-(long long)absolute;


@end

