/* MPWNeXTPListWriter.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFoundation/MPWByteStream.h>

@interface MPWNeXTPListWriter : MPWByteStream
{
    BOOL firstElementOfDict[100];
    int  currentFirstElement;
}

-(void)writeDictionaryLikeObject:anObject withContentBlock:(void (^)(MPWNeXTPListWriter* writer))contentBlock;
-(void)writeArrayContent:(NSArray*)array;

@end



@interface MPWNeXTPListWriter(testing)

+_encode:anObject;

@end


@interface NSObject(PropertyListStreaming)

-(void)writeOnPropertyList:(MPWByteStream*)aStream;

@end

