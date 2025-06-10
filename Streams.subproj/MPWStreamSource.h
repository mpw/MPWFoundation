//
//  MPWStreamSource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/12/17.
//
//

#import <MPWFoundation/MPWWriteStream.h>

@protocol Streaming,StreamSource;

@interface MPWStreamSource : NSObject <StreamSource>

@property (nonatomic, assign) bool stop;
@property (nonatomic, assign) int closeWhenDone;

-(void)run;
-(void)run:(NSTimeInterval)seconds;
-(void)runInThread;
-(void)setFinalTarget:newTarget;
-(void)awaitResultForSeconds:(NSTimeInterval)seconds;
@end
