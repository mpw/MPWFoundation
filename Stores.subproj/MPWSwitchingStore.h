//
//  MPWSwitchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWSwitchingStore : MPWDictStore

+(instancetype)storeWithStoreDictionary:(NSDictionary*)newDict;
-(instancetype)initWithStoreDictionary:(NSDictionary*)newDict;


@end
