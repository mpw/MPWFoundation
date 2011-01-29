//
//  MPWBlockInvocation.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/8/11.
//  Copyright 2011 by Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFastInvocation.h>
#if NS_BLOCKS_AVAILABLE


@interface MPWBlockInvocation : MPWFastInvocation {
	id block;
}

+invocationWithBlock:aBlock;

@end


#endif