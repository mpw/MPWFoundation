//
//  MPWURLSchemeResolver.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <MPWFoundation/MPWURLBasedStore.h>

@class MPWURLReference,MPWResource,MPWURI;

@interface MPWURLSchemeResolver : MPWURLBasedStore {
}

-(instancetype)initWithSchemePrefix:(NSString*)schemeName;

+(instancetype)httpScheme;
+(instancetype)httpsScheme;


-(NSString*)schemePrefix;
-(MPWResource*)resourceWithRequest:(NSURLRequest*)request;
-(id)at:(MPWURI*)aReference post:(id)theObject;

@property (nonatomic, strong ) NSDictionary *headers;


@end
