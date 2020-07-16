//
//  MPWBinaryPListWriter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/13.
//
//

#import <MPWFoundation/MPWNeXTPListWriter.h>

@class MPWIntArray;

//  streamWriterMessage:  writeOnPlist:


@interface MPWBinaryPListWriter : MPWNeXTPListWriter
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

-(void)writeInteger:(int)anInt forKey:(NSString*)aKey;
-(void)writeFloat:(float)aFloat forKey:(NSString*)aKey;
-(void)writeObject:anObject forKey:(NSString*)aKey;
-(void)writeString:(NSString*)anObject forKey:(NSString*)aKey;


-(void)writeArray:(NSArray*)anArray usingElementBlock:(void (^)(MPWBinaryPListWriter* writer,id randomArgument))aBlock;
-(void)writeInteger:(long)anInt;
-(void)writeFloat:(float)aFloat;
@end
