//
//  MPWDictStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWBasedStore.h>

@interface MPWRawDictStore: MPWBasedStore

@property (readonly) NSMutableDictionary *dict;

+(instancetype)storeWithDictionary:(NSMutableDictionary*)newDict;
-(instancetype)initWithDictionary:(NSMutableDictionary*)newDict;

@end

@interface MPWDictStore : MPWRawDictStore




@end
