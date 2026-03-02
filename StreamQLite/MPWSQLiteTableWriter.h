//
//  MPQSQLiteTableWriter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.03.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWSQLiteTableWriter : MPWFlattenStream

-(void)setSourceDB:(MPWStreamQLite*)sourceDB;

@property (nonatomic, strong) NSArray<MPWSQLColumnInfo*>* schema;


@end

NS_ASSUME_NONNULL_END
