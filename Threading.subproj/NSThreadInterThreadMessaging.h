/* NSThreadInterThreadMessaging.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/



#import <Foundation/Foundation.h>



@interface NSObject(asyncMessaging)

-async;
-asyncPrio;
-asyncBackground;
-asyncOn:(dispatch_queue_t)queue;
-asyncOnOperationQueue:(NSOperationQueue*)aQueue;
-onThread:(NSThread*)targetThread;
-asyncOnMainThread;
-syncOnMainThread;
-onMainThread;
-afterDelay:(NSTimeInterval)delay;


@end
