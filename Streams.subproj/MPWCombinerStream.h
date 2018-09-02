//
//  MPWCombinerStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 16/09/2016.
//
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWCombinerStream : MPWFilter

-(void)setSources:(NSArray *)newSources;

@property (assign) BOOL allowIncomplete;

@end
