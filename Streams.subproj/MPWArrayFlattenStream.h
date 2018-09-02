//
//  MPWArrayFlattenStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/18.
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWArrayFlattenStream : MPWFilter

-(void)writeArray:(NSArray*)array;

@end


@interface NSObject(MPWFlattening)

-(void)flattenOntoStream:(MPWArrayFlattenStream*)aStream;

@end
