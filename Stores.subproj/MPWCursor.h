//
//  MPWCursor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.10.23.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWCursor : NSObject

+(instancetype)cursorWithBinding:aBinding offset:(long)newOffset;
-(instancetype)initWithBinding:aBinding offset:(long)newOffset;

-value;
-(void)setValue:newValue;



@end

NS_ASSUME_NONNULL_END
