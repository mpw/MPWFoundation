/*

  MPWNamedData.h
  MPWFoundation

    Created by Marcel Weiher on 24/09/2005.
    Copyright (c) 2005-2017 by Marcel Weiher. All rights reserved.

R

*/

//

#import <Foundation/Foundation.h>


@interface MPWNamedData : NSData {
    NSString *name;
    NSData   *data;
}

-(NSString*)name;
-(void)writeToFileAtomically:(BOOL)atomic;

@end
