//
//  MPWSwitchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/18.
//

#import <MPWFoundation/MPWDictStore.h>

@interface MPWSwitchingStore : MPWDictStore

+(instancetype)storeWithStoreDictionary:(NSDictionary*)newDict;
-(instancetype)initWithStoreDictionary:(NSDictionary*)newDict;


-referenceToKey:(MPWGenericReference*)ref;          // override this in subclasses


@end
