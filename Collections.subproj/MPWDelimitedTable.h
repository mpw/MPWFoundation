//
//  MPWDelimitedTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/22/13.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWDelimitedTable : MPWObject
{
    NSData  *data;
//    NSArray *lines;
    NSArray *headerKeys;
    NSString *fieldDelimiter;
    MPWIntArray *lineOffsets;
    int eolLength;
}

@end
