//
//  SQLiteStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26.02.26.
//

#import "SQLiteStore.h"
#import "MPWStreamQLite.h"

@interface SQLiteStore()

@property (nonatomic, strong) MPWStreamQLite *db;
@property (nonatomic, strong) NSArray *tables;

@end


@implementation SQLiteStore

-(instancetype)initWithPath:(NSString*)dbPath
{
    self=[super init];
    self.db = [[[MPWStreamQLite alloc] initWithPath:dbPath] autorelease];
    [self.db open];
    self.tables = [self.db tables];
    
    return self;
}

-(id)at:(id<MPWIdentifying>)aReference
{
    return nil;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation SQLiteStore(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
