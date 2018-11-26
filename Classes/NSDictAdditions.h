/* NSDictAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

@interface NSDictionary(Additions)

- (int)integerForKey:(NSString *)defaultName;
- (float)floatForKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;
-objectForIntKey:(int)intKey;

@end
@interface NSMutableDictionary(Additions)

- (void)setInteger:(int)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
-(void)setObject:anObject forIntKey:(int)intKey;


@end
