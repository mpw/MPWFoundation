//
//  MPWScatterStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWScatterStream : MPWFilter

+(instancetype)filters:(NSArray *)filters;
-(instancetype)initWithFilters:(NSArray *)filters;

@end
