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


-(void)run;
-(void)runInThread;

@end
