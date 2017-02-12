//
//  MPWStreamSource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/12/17.
//
//

#import <Foundation/Foundation.h>

@protocol Streaming;

@interface MPWStreamSource : NSObject

@property (nonatomic, strong) NSObject <Streaming> *target;

-(void)run;
-(void)runInThread;

@end
