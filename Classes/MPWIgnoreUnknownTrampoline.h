//
//  MPWIgnoreUnknownTrampoline.h
//  MPWFoundation
//
/*
	Created by Marcel Weiher on 26/05/2005.
    Copyright (c) 2005-2017 by Marcel Weiher. All rights reserved.

R

*/

//

#import "MPWTrampoline.h"

#import "DebugMacros.h"


@interface MPWIgnoreUnknownTrampoline : MPWTrampoline {

}


@end

@interface NSObject(ifResponds)

-ifResponds;

@end
