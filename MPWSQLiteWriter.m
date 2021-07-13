//
//  MPWSQLiteWriter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import "MPWSQLiteWriter.h"
#include <sqlite3.h>



@implementation MPWSQLiteWriter
{
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *begin_transaction;
    sqlite3_stmt *end_transaction;
    sqlite3 *db;
}

-initWithSqliteDB:(sqlite3*)theDb statement:(NSString*)sql
{
    if( nil != (self=[super init]) ) {
        int rc1=0,rc2=0,rc3=0;
        db=theDb;
        rc1 = sqlite3_prepare_v2(db, [sql UTF8String], -1, &insert_stmt, 0);
        if ( !rc1 ) {
            rc2 = sqlite3_prepare_v2(db, "BEGIN TRANSACTION", -1, &begin_transaction, 0);
        }
        if ( !rc1 && !rc2 ) {
            rc3 = sqlite3_prepare_v2(db, "END TRANSACTION", -1, &end_transaction, 0);
        }
        if ( !(rc1==0 && rc2==0 && rc3==0)) {
            NSLog(@"preparing INSERT statments failed rc1=%d rc2=%d rc3=%d",rc1,rc2,rc3);
            NSLog(@"error: %s",(sqlite3_errmsg(db)));
        }
    }
    return self;
}

-(instancetype)initWithDB:(MPWStreamQLite*)theDB statement:(NSString*)sql
{
    return [self initWithSqliteDB:[theDB sqliteDB] statement:sql];
}

-(void)writeDictionary:(NSDictionary *)dict
{
    [self beginDictionary];
    for ( NSString *key in [dict allKeys]) {
        [self writeObject:dict[key] forKey:key];
    }
    [self endDictionary];
}


-(void)beginArray {
    sqlite3_step(begin_transaction);
    sqlite3_reset(begin_transaction);
}

-(void)endArray {
    sqlite3_step(end_transaction);
    sqlite3_reset(end_transaction);
}

-(void)writeObject:anObject forKey:(NSString*)aKey
{
    //    NSLog(@"MPWSQLiteWriter writeObject: '%@'/%@ forKey: %@",anObject,[anObject class],aKey);
    NSString *sql_key=[@":" stringByAppendingString:aKey];
    int paramIndex=sqlite3_bind_parameter_index(insert_stmt, [sql_key UTF8String]);
    //    NSLog(@"index for key '%@' -> '%@' is %d",aKey,sql_key,paramIndex);
    NSData *utf8data=[[[anObject stringValue] dataUsingEncoding:NSUTF8StringEncoding] retain];
    sqlite3_bind_text(insert_stmt, paramIndex, [utf8data bytes],  (int)[utf8data length],0 );
}

-(void)writeInteger:(long)anInt forKey:(NSString*)aKey
{
    //    NSLog(@"MPWSQLiteWriter writeInteger: %ld forKey: %@",anInt,aKey);
    NSString *sql_key=[@":" stringByAppendingString:aKey];
    int paramIndex=sqlite3_bind_parameter_index(insert_stmt, [sql_key UTF8String]);
    //    NSLog(@"index for key '%@' -> '%@' is %d",aKey,sql_key,paramIndex);
    sqlite3_bind_int64(insert_stmt, paramIndex, anInt);
}

-(void)endDictionary
{
    if ( insert_stmt) {
        int rc1=sqlite3_step(insert_stmt);
        int rc2=sqlite3_clear_bindings(insert_stmt);
        int rc3=sqlite3_reset(insert_stmt);
        if ( !(rc1==101 && rc2==0 && rc3==0) ) {
            NSLog(@"rc of step,clear,reset: %d %d %d",rc1,rc2,rc3);
            NSLog(@"error: %@",@(sqlite3_errmsg(db)));
        }
    }
}



//-(SEL)streamWriterMessage
//{
//    return @selector(writeOnSQLiteStream:);
//}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWSQLiteWriter(testing) 

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
