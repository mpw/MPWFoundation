//
//  MPWMessageCatcher.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 24/10/2004.
/*  
    Copyright (c) 2004-2017 by Marcel Weiher.  All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface MPWMessageCatcher : NSObject {
    NSMutableArray *messages;
    Class testClass;
}

-initWithClass:(Class)newClass;
-(NSArray*)xxxMesssages;
-(NSInvocation*)xxxMessageAtIndex:(int)anIndex;
-(NSString*)xxxMessageNameAtIndex:(int)anIndex;
-xxxMessageArgumentNumber:(int)argIndex atIndex:(int)messageIndex;
-(long)xxxMessageCount;



@end
