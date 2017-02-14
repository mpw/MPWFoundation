//
//  MPWCombinerStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 16/09/2016.
//
//

#import <MPWFoundation/MPWStream.h>

@interface MPWCombinerStream : MPWStream

-(void)setSources:(NSArray *)newSources;

@property (assign) BOOL allowIncomplete;

@end
