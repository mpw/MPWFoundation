//
//  MPWFixedValueSource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.05.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWFixedValueSource : MPWFilter

@property (nonatomic, strong) NSArray *values;
@property (assign) NSTimeInterval seconds;

-(NSTimer*)timer;

@end

NS_ASSUME_NONNULL_END
