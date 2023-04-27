//
//  MPWKeychainStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26.04.23.
//

#import "MPWKeychainStore.h"
#import <Security/Security.h>

@implementation MPWKeychainStore

-(NSMutableDictionary*)queryDictForReference:(id<MPWReferencing>)aReference
{
    NSArray *path=[aReference relativePathComponents];
    if ( [path.firstObject isEqual:@"password"] && path.count==3) {
        NSString *server=path[1];
        NSString *account=path[2];
        NSDictionary *query = @{
            (id)kSecClass: (id)kSecClassInternetPassword,
            (id)kSecAttrServer: [server retain],
            (id)kSecAttrAccount: [account retain],
        };
        return [[query mutableCopy] autorelease];
    } else {
        @throw [NSException exceptionWithName:@"keychainError" reason:@"invalid path error" userInfo:nil];
    }
    return nil;
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    NSMutableDictionary *addQuery=[self queryDictForReference:aReference];
    addQuery[(id)kSecValueData]=[theObject asData];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    if (status != errSecSuccess) {
        NSLog(@"status: %d",status);
        @throw [NSException exceptionWithName:@"keychainWriteError" reason:@"keychain error" userInfo:nil];
    }
}

-(id)at:(id<MPWReferencing>)aReference
{
    NSMutableDictionary *query=[self queryDictForReference:aReference];
    query[(id)kSecReturnData]=@(true);
    id retval=nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (  CFTypeRef _Nullable*)&retval);
    if (status != errSecSuccess && status != -25300) {

        @throw [NSException exceptionWithName:@"keychainReadError" reason:@"keychain read error" userInfo:nil];
    }
    return retval;
}

-(void)deleteAt:(id<MPWReferencing>)aReference
{
    OSStatus status = SecItemDelete((CFDictionaryRef)[self queryDictForReference:aReference]);
    if (status != errSecSuccess &&  status != -25300) {
        
        @throw [NSException exceptionWithName:@"keychainReadError" reason:@"keychain read error" userInfo:nil];
    }
    return ;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWKeychainStore(testing) 

+(void)testCanStoreAndRetrievePasswordInKeychain
{
    NSString *passwordPath=@"password/www.metaobject.com/mweiher";
    NSString *thePassword=@"passwordForMWeiher";
    MPWKeychainStore *keychain=[self store];
    
    [keychain deleteAt:passwordPath];
    EXPECTNIL(keychain[passwordPath],@"shouldn't be there before we store it");
    keychain[passwordPath]=thePassword;
    IDEXPECT([keychain[passwordPath] stringValue],thePassword,@"password we stored");
    [keychain deleteAt:passwordPath];
    EXPECTNIL(keychain[passwordPath],@"shouldn't be there after we delete it");

}

+(NSArray*)testSelectors
{
   return @[
			@"testCanStoreAndRetrievePasswordInKeychain",
			];
}

@end
