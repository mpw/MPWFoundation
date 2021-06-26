/* MPWFlattenStream.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFoundation/MPWArrayFlattenStream.h>
#import <MPWFoundation/MPWPListBuilder.h>

@interface MPWFlattenStream : MPWArrayFlattenStream <MPWPlistStreaming>
{

}

-(void)writeDictionary:(NSDictionary*)dict;
-(void)writeKeyEnumerator:(NSEnumerator*)keys withDict:(NSDictionary*)dict;
-(void)createEncoderMethodForClass:(Class)theClass;


@end

@interface NSObject(StructureFlattening)

-(void)flattenStructureOntoStream:(MPWFlattenStream*)aStream;

@end

