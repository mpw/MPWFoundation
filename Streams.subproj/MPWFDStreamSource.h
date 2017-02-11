//
//  MPWFDStreamSource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/11/17.
//
//

#import <Foundation/Foundation.h>

@protocol Streaming;

@interface MPWFDStreamSource : NSObject

@property (nonatomic, strong) id <Streaming> target;
@property (nonatomic, assign) int fdin;

-initWithFD:(int)fd;
+fd:(int)fd;
-(void)run;
-(void)runInThread;

@end
