//
//  MPWDictStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWAbstractStore.h>

@interface MPWDictStore : MPWAbstractStore

+(instancetype)storeWithDictionary:(NSMutableDictionary*)newDict;
-(instancetype)initWithDictionary:(NSMutableDictionary*)newDict;

@property (readonly) NSMutableDictionary *dict;


@end
