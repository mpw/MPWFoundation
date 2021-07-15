//
//  MPWSQLiteWriter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWSQLiteWriter : MPWFlattenStream

-(instancetype)initWithDB:(MPWStreamQLite*)db statement:(NSString*)sql;
-(void)beginArray;
-(void)endArray;
-(void)writeInteger:(long)anInt forKey:(NSString*)aKey;

@end


NS_ASSUME_NONNULL_END
