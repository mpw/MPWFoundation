//
//  MPWNumber.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 20/3/07.
//  Copyright 2010-2017 by Marcel Weiher. All rights reserved.
//

#import <MPWObject.h>


@interface MPWNumber : MPWObject {

}
-(BOOL)isEqualToFloat:(float)floatValue;
-(BOOL)isEqualToInteger:(int)intValue;
@end

@interface MPWNumber(subclasses)
-(int)intValue;
-(float)floatValue;
-(NSString*)stringValue;
-negate;
@end

