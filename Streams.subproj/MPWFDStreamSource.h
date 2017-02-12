//
//  MPWFDStreamSource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/11/17.
//
//

#import <MPWFoundation/MPWStreamSource.h>


@interface MPWFDStreamSource : MPWStreamSource

@property (nonatomic, assign) int fdin;
@property (nonatomic, assign) int closeWhenDone;

-initWithFilename:(NSString *)filename;
-initWithFD:(int)fd;
+fd:(int)fd;
+name:(NSString*)filename;

@end
