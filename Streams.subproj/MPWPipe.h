//
//  MPWPipe.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/05/16.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWPipe : MPWStream

@property (nonatomic, strong) NSArray *filters;

-(void)setErrorTarget:newErrorTarget;

@end
