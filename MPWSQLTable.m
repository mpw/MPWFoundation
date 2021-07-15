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
#import "MPWSQLColumnInfo.h"

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

-(NSArray*)objectsForQuery:(NSString*)query builder:(MPWPListBuilder*)builder
{
    [self.db setBuilder:builder];
    [self.db query:query];
    return [[self.db builder] result];
}

-(MPWPListBuilder*)defaultBuilder
{
    return self.tableClass ? [[[MPWObjectBuilder alloc] initWithClass: self.tableClass] autorelease] :
    [MPWPListBuilder builder];
}

-(NSArray*)objectsForQuery:(NSString*)query
{
    return [self objectsForQuery:query builder:[self defaultBuilder]];
}

-(NSInteger)count
{
    return [[[[self objectsForQuery:[NSString stringWithFormat:@"select count(*) from %@",self.name] builder:[MPWPListBuilder builder]] firstObject] at:@"count(*)"] longValue];
}


-(NSArray<MPWSQLColumnInfo*>*)schema
{
    NSArray *resultSet = [self objectsForQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)",self.name] builder:[[[MPWObjectBuilder alloc] initWithClass: [MPWSQLColumnInfo class]] autorelease]];
    return resultSet;
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

+(void)testGetTableSchema
{
    MPWStreamQLite *db=[MPWStreamQLite _chinookDB];
    MPWSQLTable *artists=[db tables][@"artists"];
    NSArray *schema=[artists schema];
    INTEXPECT(schema.count,2,@"columns");
    MPWSQLColumnInfo *nameColumn=schema.lastObject;
    MPWSQLColumnInfo *idColumn=schema.firstObject;
    IDEXPECT(idColumn.name, @"ArtistId", @"name of id column");
    IDEXPECT(idColumn.type, @"INTEGER", @"type of id column");
    EXPECTTRUE(idColumn.pk, @"ArtistId is primary key");
    EXPECTTRUE(idColumn.notnull, @"ArtistId not null");
    IDEXPECT(nameColumn.name, @"Name", @"name of 'name' column");
    IDEXPECT(nameColumn.type, @"NVARCHAR(120)", @"type of 'name' column");
    EXPECTFALSE(nameColumn.pk, @"name is primary key");
    EXPECTFALSE(nameColumn.notnull, @"name not null");
}

+(void)testCount
{
    MPWStreamQLite *db=[MPWStreamQLite _chinookDB];
    MPWSQLTable *artists=[db tables][@"artists"];
    INTEXPECT( artists.count, 275, @"number of artists");
}

+(NSArray*)testSelectors
{
    return @[
        @"testSQLForInsert",
        @"testGetTableSchema",
        @"testCount",
    ];
}

@end
