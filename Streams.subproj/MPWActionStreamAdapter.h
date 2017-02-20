//
//  MPWActionStreamAdapter.h
//  FlowChat
//
//  Created by Marcel Weiher on 2/13/17.
//  Copyright © 2017 metaobject. All rights reserved.
//

#import <MPWFoundation/MPWStream.h>

@interface MPWActionStreamAdapter : MPWStream

-initWithUIControl:aControl target:aTarget;
-initWithTextField:aControl target:aTarget;

@end
