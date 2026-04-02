//
//  MPQSQLiteTableWriter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.03.26.
//

#import "MPWSQLiteTableWriter.h"
#import <MPWFoundation/MPWByteStream.h>
#import "MPWSQLColumnInfo.h"

#import <sqlite3.h>


@interface MPWSQLiteTableWriter()


@end



@implementation MPWSQLiteTableWriter
{
    sqlite3 *sqlitedb;
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *begin_transaction;
    sqlite3_stmt *end_transaction;
    id keys[100];
    int numKeys;
    NSMutableArray<NSMutableData*>* buffers;
    char *bufferpointers[100];
    NSMutableDictionary<NSString*,NSNumber*> *insertParams;
}

-(void)setSourceDB:(MPWStreamQLite*)sourceDB
{
//    self.db = sourceDB;
    sqlitedb = [sourceDB sqliteDB];
    [self createBuffers];
}

-(void)createBuffers
{
    int numBuffers=(int)[[[self schema] fields] count];
    buffers=[[NSMutableArray alloc] init];
    for (int i=0;i<numBuffers+1;i++) {
        [buffers addObject:[NSMutableData dataWithCapacity:8192]];
        bufferpointers[i]=[buffers[i] mutableBytes];
    }
}


-(NSString*)computeSQLForInsertWithKeys:(NSArray<NSString*>*)sqlKeys
{
    NSMutableString *sql=[NSMutableString string];
    MPWByteStream *s=[MPWByteStream streamWithTarget:sql];
    [s printFormat:@"INSERT INTO %@ (",[self name]];
    BOOL first=YES;
    for ( NSString *key in sqlKeys ) {
        [s printFormat:@"%s%@",first?"":", ",key];
        first=NO;
    }
    first=YES;
    [s printFormat:@") VALUES ("];
    for ( NSString *key in sqlKeys ) {
        [s printFormat:@"%s:%@",first?"":", ",key];
        first=NO;
    }
    [s printFormat:@");"];
    return sql;
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


-(int)paramIndexForKey:(NSString*)aKey
{
    for (int i=0;i<=numKeys;i++) {
        if ( keys[i]==aKey) {
            return i;
        }
    }
    NSLog(@"did not find key: %@ %p",aKey,aKey);
    NSNumber *paramIndex=insertParams[aKey];
    int paramIndexInt=paramIndex.intValue;
    if (!paramIndex) {
        NSString *sql_key=[@":" stringByAppendingString:aKey];
        [self createInsertStatement];
        paramIndexInt=sqlite3_bind_parameter_index(insert_stmt, [sql_key UTF8String]);
        if ( !insertParams) {
            insertParams=[[NSMutableDictionary alloc] init];
        }
        insertParams[aKey]=@(paramIndexInt);
        keys[paramIndexInt]=[aKey copy];
        if ( paramIndexInt > numKeys ) {
            numKeys = paramIndexInt;
        }
    }
    return paramIndexInt;
}

-(void)writeObject:anObject forKey:(NSString*)aKey
{
    if ( anObject ) {
        [self createInsertStatement];
        int keyIndex=[self paramIndexForKey:aKey];
        char *buffer=bufferpointers[keyIndex];
        NSInteger len = [[anObject stringValue] getISOLatinCharacters:buffer];
        sqlite3_bind_text(insert_stmt,keyIndex , buffer,  (int)len ,0 );
    }
    
}

-(void)writeInteger:(long)anInt forKey:(NSString*)aKey
{
    //    NSLog(@"MPWSQLiteWriter writeInteger: %ld forKey: %@",anInt,aKey);
    //    NSLog(@"index for key '%@' -> '%@' is %d",aKey,sql_key,paramIndex);
    [self createInsertStatement];
    sqlite3_bind_int64(insert_stmt, [self paramIndexForKey:aKey], anInt);
}

-(void)endDictionary
{
    if ( insert_stmt) {
        int rc1=sqlite3_step(insert_stmt);
        int rc2=sqlite3_clear_bindings(insert_stmt);
        int rc3=sqlite3_reset(insert_stmt);
        if ( !(rc1==101 && rc2==0 && rc3==0) ) {
            NSLog(@"rc of step,clear,reset: %d %d %d",rc1,rc2,rc3);
            NSLog(@"error: %@",@(sqlite3_errmsg(sqlitedb)));
        }
    }
}

-(void)createInsertStatement
{
    if ( !insert_stmt) {
        int rc1,rc2=0,rc3=0;
        NSString *sqlForInsertComputed=[self computeSQLForInsert];
        NSLog(@"sqliteForInsert: '%@'",sqlForInsertComputed);

        rc2 = sqlite3_prepare_v2(sqlitedb, "BEGIN TRANSACTION", -1, &begin_transaction, 0);
        rc1 = sqlite3_prepare_v2(sqlitedb, [sqlForInsertComputed UTF8String], -1, &insert_stmt, 0);
        NSString *error = @(sqlite3_errmsg(sqlitedb));
        rc3 = sqlite3_prepare_v2(sqlitedb, "END TRANSACTION", -1, &end_transaction, 0);
        if ( !(rc1==0 && rc2==0 && rc3==0)) {
            NSLog(@"preparing INSERT statments for table '%@' failed rc1=%d rc2=%d rc3=%d",self.name,rc1,rc2,rc3);
            NSLog(@"error: %@",error);
            NSLog(@"computed SQL for insert: %@",sqlForInsertComputed);
            [NSException raise:@"sqllite" format:@"creating insert command failed rc1=%d rc2=%d rc3=%d msg=%@",rc1,rc2,rc3,error];
        }
    }
    
}

-(NSArray*)insertKeys
{
    NSMutableArray *insertKeys=[NSMutableArray array];
    for ( MPWSQLColumnInfo *column in [[self schema] fields]) {
        if ( !([column.type isEqual:@"INTEGER"] && column.pk) ) {
            [insertKeys addObject:column.name];
        }
    }
    return insertKeys;
}

-(NSString*)computeSQLForInsert
{
    return [self computeSQLForInsertWithKeys: [self insertKeys]];
}


-(void)dealloc
{
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSQLiteTableWriter(testing) 


+(void)testSQLForInsert
{
    MPWSQLiteTableWriter *writer=[[self new] autorelease];
    writer.name=@"tasks";
    NSString *insertSQL=[writer computeSQLForInsertWithKeys:@[ @"id", @"title", @"completed"]];
    IDEXPECT(insertSQL,@"INSERT INTO tasks (id, title, completed) VALUES (:id, :title, :completed);",@"SQL for insert");
}


+(NSArray*)testSelectors
{
   return @[
			@"testSQLForInsert",
			];
}

@end
