//
//  MPWSQLTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import <MPWFoundation/MPWTable.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStreamQLite,MPWSQLColumnInfo;

@interface MPWSQLiteTable : MPWTable

@property (nonatomic,assign) Class tableClass;
@property (nonatomic,weak) MPWStreamQLite *db;
@property (nonatomic, strong) NSString *name;

-(NSArray<MPWSQLColumnInfo*>*)schema;
-(void)setSourceDB:(MPWStreamQLite*)sourceDB;

@end


NS_ASSUME_NONNULL_END
