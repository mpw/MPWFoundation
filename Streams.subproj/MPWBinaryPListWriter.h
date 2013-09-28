//
//  MPWBinaryPListWriter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/13.
//
//

#import "MPWPropertyListStream.h"

@class MPWIntArray;

//  streamWriterMessage:  writeOnPlist:


@interface MPWBinaryPListWriter : MPWPropertyListStream
{
    MPWIntArray *offsets;
    int         offsetOfOffsetTable;
    __unsafe_unretained MPWIntArray *currentIndexes;
    NSMutableArray *indexStack;
    NSMutableArray *reserveIndexes;
    NSMapTable     *objectTable;
    BOOL        headerWritten;
    int         inlineOffsetByteSize;
    
}


-(void)beginDictionary;
-(void)endDictionary;
-(void)writeString:(NSString *)aString;
-(void)beginArray;
-(void)endArray;

-(void)writeArray:(NSArray*)anArray usingElementBlock:(WriterBlock)aBlock;

-(void)writeInt:(int)anInt forKey:(NSString*)aKey;
-(void)writeFloat:(float)aFloat forKey:(NSString*)aKey;
-(void)writeInteger:(long)anInt;
-(void)writeFloat:(float)aFloat;
@end
