//
//  MPWBinaryPlist.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/27/13.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWBinaryPlist : MPWObject
{
    NSData  *data;
    const unsigned char *bytes;
    long  dataLen;
    long    rootIndex;
    long    numObjects;
    long    offsetTableLocation;
    long    *offsets;
    id      *objects;
    int     offsetIntegerSizeInBytes;
    int     offsetReferenceSizeInBytes;
}

@end
