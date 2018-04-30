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
    long         offsetOfOffsetTable;
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

-(void)writeInt:(int)anInt forKey:(NSString*)aKey;
-(void)writeFloat:(float)aFloat forKey:(NSString*)aKey;
-(void)writeObject:anObject forKey:(NSString*)aKey;


-(void)writeArray:(NSArray*)anArray usingElementBlock:(WriterBlock)aBlock;
-(void)writeInteger:(long)anInt;
-(void)writeFloat:(float)aFloat;
@end
