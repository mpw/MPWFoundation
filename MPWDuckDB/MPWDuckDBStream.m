//
//  MPWDuckDBStream.m
//  MPWDuckDB
//
//  Created by Marcel Weiher on 04.05.25.
//

#import "MPWDuckDBStream.h"
#include "duckdb.h"

@implementation MPWDuckDBStream

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDuckDBStream(testing) 

+(void)testDBReading
{
    NSString *dbp=[self frameworkPath:@"duckdb-demo.duckdb"];
    EXPECTNOTNIL(dbp, @"test db path");
    duckdb_database db = NULL;
    duckdb_connection con = NULL;
    duckdb_result result;
    
    if (duckdb_open([dbp UTF8String], &db) == DuckDBError) {
        fprintf(stderr, "Failed to open database\n");
        goto cleanup;
    }
    if (duckdb_connect(db, &con) == DuckDBError) {
        fprintf(stderr, "Failed to open connection\n");
        goto cleanup;
    }
    if (duckdb_query(con, "SELECT * from bank_failures", &result) == DuckDBError) {
        fprintf(stderr, "Failed to query database\n");
        goto cleanup;
    }
    // print the names of the result
    idx_t row_count = duckdb_row_count(&result);
    idx_t column_count = duckdb_column_count(&result);
    printf("rows: %llu\n",row_count);
    printf("columns: %llu\n",column_count);
    for (size_t i = 0; i < column_count; i++) {
        printf("column[%ld] = %s\n ", i, duckdb_column_name(&result, i));
    }
    printf("\n");
    // print the data of the result
    for (size_t row_idx = 0; row_idx < row_count; row_idx++) {
        for (size_t col_idx = 0; col_idx < column_count; col_idx++) {
            char *val = duckdb_value_varchar(&result, col_idx, row_idx);
            printf("%s ", val);
            duckdb_free(val);
        }
        printf("\n");
    }
    // duckdb_print_result(result);
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
