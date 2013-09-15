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
    NSMapTable     *objectTable;
}

typedef void (^WriterBlock)(MPWBinaryPListWriter* writer,id randomArgument);

-(void)beginDictionary;
-(void)endDictionary;
-(void)writeString:(NSString *)aString;
-(void)beginArray;
-(void)endArray;

-(void)writeArray:(NSArray*)anArray usingElementBlock:(WriterBlock)aBlock;

-(void)writeInt:(int)anInt forKey:(NSString*)aKey;

@end
