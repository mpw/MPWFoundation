//
//  MPWSQLTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import "MPWSQLTable.h"
#import "AccessorMacros.h"
#import "MPWByteStream.h"
#import "MPWStreamQLite.h"
#import "MPWObjectBuilder.h"

@implementation MPWSQLTable {
    NSString *sqlForInsert;
    NSString *sqlForCreate;
}

lazyAccessor(NSString, sqlForInsert, setSqlForInsert, computeSQLForInsert )
lazyAccessor(NSString, sqlForCreate, setSqlForCreate, computeSQLForCreate )

+(NSArray*)sqlInsertKeys { return @[]; }

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

-(NSString*)computeSQLForInsert
{
    return [self computeSQLForInsertWithKeys: [self.tableClass sqlInsertKeys]];
}

-(NSString*)computeSQLForCreate
{
    NSString *classSpecificSQL=[self.tableClass sqlForCreate];
    return [NSString stringWithFormat:@"CREATE TABLE %@ %@ ",[self name],classSpecificSQL];
}

-(void)create
{
    [self.db query:[self sqlForCreate]];
}

-(void)insert:array
{
    MPWSQLiteWriter *writer = [self.db insert: [self sqlForInsert]];
    [writer writeObject:array];
}

-(NSArray*)objectsForQuery:(NSString*)query
{
    MPWObjectBuilder *builder = [[[MPWObjectBuilder alloc] initWithClass: self.tableClass] autorelease];
    [self.db setBuilder:builder];
    [self.db query:query];
    return [[self.db builder] result];
}

-select
{
    return [self objectsForQuery:[NSString stringWithFormat:@"select * from %@",self.name]];
}

-selectWhere:query
{
    return [self objectsForQuery:[NSString stringWithFormat:@"select * from %@ where %@",self.name,query]];
}

@end

@implementation MPWSQLTable(testing)

+(void)testSQLForInsert
{
    MPWSQLTable *table=[[MPWSQLTable new] autorelease];
    table.name=@"tasks";
    NSString *insertSQL=[table computeSQLForInsertWithKeys:@[ @"id", @"title", @"completed"]];
    IDEXPECT(insertSQL,@"INSERT INTO tasks (id, title, completed) VALUES (:id, :title, :completed);",@"SQL for insert");
}

+(NSArray*)testSelectors
{
    return @[
        @"testSQLForInsert",
    ];
}

@end
