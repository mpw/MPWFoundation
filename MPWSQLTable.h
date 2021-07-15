//
//  MPWSQLTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStreamQLite,MPWSQLColumnInfo;

@interface MPWSQLTable : NSObject


@property (nonatomic,assign) Class tableClass;
@property (nonatomic,weak) MPWStreamQLite *db;
@property (nonatomic,strong) NSString *name;

-(NSArray<MPWSQLColumnInfo*>*)schema;

@end


NS_ASSUME_NONNULL_END
