//
//  MPWJSONWriter.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWNeXTPListWriter.h>


@interface MPWJSONWriter : MPWNeXTPListWriter {
}

-(void)writeNull;
-(void)writeInteger:(long)number;
-(void)writeFloat:(float)number;
-(void)writeInteger:(long)number forKey:(NSString*)aKey;
-(void)writeString:(NSString*)string forKey:(NSString*)aKey;

@end

@interface MPWJSONWriter(redeclare)

-(void)writeDictionaryLikeObject:anObject withContentBlock:(void (^)(id object, MPWJSONWriter* writer))contentBlock;
-(void)createEncoderMethodForClass:(Class)theClass;



@end

@interface NSObject(jsonWriting)

-(void)writeOnJSONStream:(MPWJSONWriter*)aStream;

@end
