//
//  MPWSQLTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStreamQLite,MPWSQLColumnInfo;

@interface MPWSQLiteTable : MPWFlattenStream

@property (nonatomic,assign) Class tableClass;
@property (nonatomic,weak) MPWStreamQLite *db;

-(NSArray<MPWSQLColumnInfo*>*)schema;
-(void)setSourceDB:(MPWStreamQLite*)sourceDB;

@end


NS_ASSUME_NONNULL_END
