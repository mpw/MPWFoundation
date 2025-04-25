//
//  MPWStoreURLSchemeHandler.h
//  SiteBuilder
//
//  Created by Marcel Weiher on 01.03.19.
//

#import <MPWFoundation/MPWFoundation.h>
#import <WebKit/WebKit.h>

@protocol MPWStorage;

@interface MPWStoreURLSchemeHandler : NSObject <WKURLSchemeHandler>

-(instancetype)initWithStore:(id <MPWStorage>) store;

@property (nonatomic,strong) id <MPWStorage> store;
@property (nonatomic,strong) id <Streaming> requestLog;
@property (nonatomic,strong) id <Streaming> responseLog;

@end
