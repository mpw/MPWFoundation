//
//  MPWDuckDBStream.m
//  MPWDuckDB
//
//  Created by Marcel Weiher on 04.05.25.
//

#import "MPWDuckDBStream.h"
#include "duckdb.h"

@implementation MPWDuckDBStream
{
    duckdb_database db;
    duckdb_connection con;
    duckdb_result result;
}

-initWithPath:(NSString*)path
{
    self=[super init];
    if ( self ) {
        if (duckdb_open([path UTF8String], &db) == DuckDBError) {
            fprintf(stderr, "Failed to open database\n");
            return nil;
        }
        if (duckdb_connect(db, &con) == DuckDBError) {
            fprintf(stderr, "Failed to open connection\n");
            return nil;
        }
    }
    return self;
}



-(BOOL)query:(NSString*)sql
{
    if (duckdb_query(con, "SELECT * from bank_failures", &result) != DuckDBError) {
        NSMutableArray *columnNames=[NSMutableArray array];
        for (size_t i = 0; i < [self numCols]; i++) {
            [columnNames addObject:@(duckdb_column_name(&result, i))];
        }
        NSLog(@"column names: %@",columnNames);
        [self.builder beginArray];
        for (size_t row_idx = 0, row_count=[self numRows]; row_idx < row_count; row_idx++) {
            [self.builder beginDictionary];
            for (size_t col_idx = 0, col_count=[self numCols]; col_idx < col_count; col_idx++) {
                char *cstrval=duckdb_value_varchar(&result, col_idx, row_idx);
                NSString *value=@(duckdb_value_varchar(&result, col_idx, row_idx));
                [self.builder writeObject:value forKey:columnNames[col_idx]];
                duckdb_free(cstrval);
            }
            [self.builder endDictionary];
        }
        [self.builder endArray];
        return YES;
    } else {
        return NO;
    }
}

-(long long)numRows
{
    return duckdb_row_count(&result);
}

-(long long)numCols
{
    return duckdb_column_count(&result);
}

-(void)printColums
{
    for (size_t i = 0; i < [self numCols]; i++) {
        printf("column[%ld] = %s\n ", i, duckdb_column_name(&result, i));
    }
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDuckDBStream(testing) 


+(void)testDBReading
{
    NSString *dbp=[self frameworkPath:@"duckdb-demo.duckdb"];
    EXPECTNOTNIL(dbp, @"test-db path");
    MPWDuckDBStream *db=[[[self alloc] initWithPath:dbp] autorelease];
    MPWPListBuilder *builder=[MPWPListBuilder builder];
    db.builder = builder;
    EXPECTNOTNIL(db, @"test-db");
    NSLog(@"will execute query!");
    EXPECTTRUE( [db query:@"SELECT * from bank_failures"] , @"query succeeded");
    NSArray<NSDictionary*> *failedBanks=[db.builder result];
    NSLog(@"failedBanks: %@",failedBanks);
    INTEXPECT(failedBanks.count, 545, @"number of banks");


cleanup:
    //    duckdb_destroy_result(&result);
    //    duckdb_disconnect(&con);
    //    duckdb_close(&db);
}

+(NSArray*)testSelectors
{
   return @[
			@"testDBReading",
			];
}

@end
