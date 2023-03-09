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
@property (nonatomic, assign) int bufferSize;

-initWithFilename:(NSString *)filename;
-initWithFD:(int)fd;
+fd:(int)fd;
+Stdin;
+name:(NSString*)filename;

@end
