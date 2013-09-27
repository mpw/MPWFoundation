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
    BOOL    lazyArray;
}

typedef void (^ArrayElementBlock)(MPWBinaryPlist* plist,long offset,long anIndex);

typedef void (^DictElementBlock)(MPWBinaryPlist* plist,long keyOffset,long valueOffset,long anIndex);



-initWithData:(NSData*)newPlistData;
+bplistWithData:(NSData*)newPlistData;
-(long)parseIntegerAtOffset:(long)offset;
-(long)offsetOfObjectNo:(long)offsetNo;
-(long)_rootOffset;

-(long)parseArrayAtIndex:(long)anIndex usingBlock:(ArrayElementBlock)block;

-(NSArray*)readArrayAtIndex:(long)anIndex;
-(long)parseDictAtIndex:(long)anIndex usingBlock:(DictElementBlock)block;
-(NSDictionary*)readDictAtIndex:(long)anIndex;
-(BOOL)isArrayAtIndex:(long)anIndex;
-objectAtIndex:(NSUInteger)anIndex;
-(long)rootIndex;

@end
