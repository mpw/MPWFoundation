//
//  MPWBinaryPListWriter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/13.
//
//

#import "MPWByteStream.h"

@class MPWIntArray;

@interface MPWBinaryPListWriter : MPWByteStream
{
    MPWIntArray *offsets;
    int         offsetOfOffsetTable;
    MPWIntArray *currentIndexes;
    NSMutableArray *indexStack;
    NSMutableArray *reserveIndexes;
}

@end
