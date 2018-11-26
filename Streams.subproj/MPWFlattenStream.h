/* MPWFlattenStream.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFoundation/MPWArrayFlattenStream.h>

@interface MPWFlattenStream : MPWArrayFlattenStream
{

}

-(void)writeDictionary:(NSDictionary*)dict;
-(void)writeKeyEnumerator:(NSEnumerator*)keys withDict:(NSDictionary*)dict;


@end

@interface NSObject(StructureFlattening)

-(void)flattenStructureOntoStream:(MPWFlattenStream*)aStream;

@end

