//
//  MPWSQLTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import "MPWSQLiteTable.h"
#import "AccessorMacros.h"
#import "MPWByteStream.h"
#import "MPWStreamQLite.h"
#import "MPWObjectBuilder.h"
#import "MPWSQLColumnInfo.h"
#import "MPWSQLiteTableWriter.h"
#import <sqlite3.h>


@interface NSString(getISOLatinCharacters)
-(NSInteger)getISOLatinCharacters:(char*)buffer;
@end

@implementation NSString(getISOLatinCharacters)
-(NSInteger)getISOLatinCharacters:(char*)buffer
{
    NSInteger len=self.length;
    unichar unibuf[len+10];
    [self getCharacters:unibuf range:NSMakeRange(0,len)];
    for (int i=0;i<len;i++) {
        buffer[i]=unibuf[i];
    }
    //        NSUInteger len=0;
    //        [s getBytes:buffer maxLength:8192 usedLength:&len encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0,s.length) remainingRange:NULL];
    buffer[len]=0;
    return len;
}
@end



@implementation MPWSQLiteTable {
//    NSString *sqlForInsert;
    NSString *sqlForCreate;
    sqlite3 *sqlitedb;
    MPWSQLiteTableWriter *writer;
    NSArray<MPWSQLColumnInfo*>* schema;
}

//lazyAccessor(NSString*, sqlForInsert, setSqlForInsert, computeSQLForInsert )
lazyAccessor(NSString*, sqlForCreate, setSqlForCreate, computeSQLForCreate )
lazyAccessor(MPWSQLiteTableWriter *, writer, setWriter, createWriter )
lazyAccessor( NSArray<MPWSQLColumnInfo*>*, schema, setSchema, getSchema )


-(void)setSourceDB:(MPWStreamQLite*)sourceDB
{
    self.db = sourceDB;
    sqlitedb = [sourceDB sqliteDB];
//    [self createInsertStatement];
//    [self createBuffers];
}

-(MPWSQLiteTableWriter*)createWriter
{
    MPWSQLiteTableWriter *theWriter = [[[MPWSQLiteTableWriter alloc] init] autorelease];
    theWriter.name = self.name;
    theWriter.schema = self.schema;
    [theWriter setSourceDB:self.db];
    return theWriter;
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
    [self writeObject:array];
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


-(NSArray<MPWSQLColumnInfo*>*)getSchema
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

-selectPredicate:(NSPredicate*)predicate
{
    return [self selectWhere:[predicate predicateFormat]];
}


-evaluateQuery:aQuery inContext:aContext
{
    return [self selectPredicate:[[aQuery predicate] asNSPredicate]];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: name: %@ columns: %@>",self.className,self,self.name,self.schema];
}

@end

@implementation MPWSQLiteTable(testing)


+(void)testGetTableSchema
{
    MPWStreamQLite *db=[MPWStreamQLite _chinookDB];
    MPWSQLiteTable *artists=[db tables][@"artists"];
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
//    EXPECTFALSE(nameColumn.pk, @"name is primary key");
//    EXPECTFALSE(nameColumn.notnull, @"name not null");
}

+(void)testCount
{
    MPWStreamQLite *db=[MPWStreamQLite _chinookDB];
    MPWSQLiteTable *artists=[db tables][@"artists"];
    INTEXPECT( artists.count, 275, @"number of artists");
}

+(NSArray*)testSelectors
{
    return @[
        @"testGetTableSchema",
        @"testCount",
    ];
}

@end

