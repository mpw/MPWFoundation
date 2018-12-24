//
//  MPWBlockInvocation.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/8/11.
//  Copyright 2012 by Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFastInvocation.h>


@interface MPWBlockInvocation : MPWFastInvocation {
	id block;
}

+invocationWithBlock:aBlock;

@end


