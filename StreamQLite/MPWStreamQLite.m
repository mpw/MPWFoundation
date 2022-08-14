//
//  MPWStreamQLite.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.06.20.
//

#import "MPWStreamQLite.h"
#import "MPWPListBuilder.h"
#import "MPWFlattenStream.h"
#import "MPWObjectBuilder.h"
#import "MPWSQLTable.h"

#include <sqlite3.h>

@interface MPWStreamQLite()

@property (nonatomic, strong) NSString *databasePath;

@end



@implementation MPWStreamQLite
{
    sqlite3 *db;
    NSDictionary <NSString*,MPWSQLTable*>* tables;
}

lazyAccessor(NSDictionary*, tables, setTables, getTables )

+(instancetype)open:(NSString*)newpath
{
    MPWStreamQLite *db=[[[self alloc] initWithPath:newpath] autorelease];
    if ([db open]==0) {
        return db;
    } else {
        [self release];
        return nil;
    }
}

+(instancetype)memory
{
    return [self open:@":memory:"];
}

-(instancetype)initWithPath:(NSString*)newpath
{
    self=[super init];
    self.databasePath = newpath;
    return self;
}

-(int)query:(NSString*)sql
{
    sqlite3_stmt *res;
    int rc = sqlite3_prepare_v2(db, [sql UTF8String], -1, &res, 0);
    @autoreleasepool {
        [self.builder beginArray];
        int step;
        int numCols=sqlite3_column_count(res);
        NSString* keys[numCols];
        for (int i=0;i<numCols;i++) {
            keys[i]=@(sqlite3_column_name(res, i));
        }
        while ( SQLITE_ROW == (step = sqlite3_step(res))) {
            @autoreleasepool {
                [self.builder beginDictionary];
                for (int i=0; i<numCols;i++) {
                    int coltype=sqlite3_column_type(res, i);
                    switch ( coltype ) {
                        case SQLITE_INTEGER:
                        {
                            long value=sqlite3_column_int64(res, i);
                            [self.builder writeObject:@(value) forKey:keys[i]];
                            break;
                        }
                        default:
                        {
                            const char *text=(const char*)sqlite3_column_text(res, i);
                            if (text) {
                                NSString *value=@(text);
                                [self.builder writeObject:value forKey:keys[i]];
                            }
                        }
                    }
                }
                [self.builder endDictionary];
            }
        }
        sqlite3_finalize(res);
        [self.builder endArray];
    }
    return rc;
}

-(void*)sqliteDB
{
    return db;
}

-(int)open
{
    return sqlite3_open([self.databasePath UTF8String], &db);
}

-(NSArray*)dbTableNames
{
    [self setBuilder:[MPWPListBuilder builder]];
    [self query:@"select name from sqlite_master where [type] = \"table\""];
    NSMutableArray *names=[[[[[self.builder result] collect] objectForKey:@"name"] mutableCopy] autorelease];
    [names removeObject:@"schema"];
    return names;
}

-(NSArray<MPWSQLTable*>*)getTablesList
{
    NSMutableArray *computedTables=[NSMutableArray array];
    for ( NSString *name in [self dbTableNames]){
        MPWSQLTable *table=[[MPWSQLTable new] autorelease];
        table.name=name;
        [table setSourceDB:self];
        [computedTables addObject:table];
    }
    return computedTables;
}

-(NSDictionary<NSString*,MPWSQLTable*>*)getTables
{
    return [NSDictionary dictionaryWithObjects:[self getTablesList] byKey:@"name"];
}

-(void)enableWAL
{
    [self query:@"PRAGMA journal_mode=WAL;"];
}


-(void)close
{
    if (db) {
        sqlite3_close(db);
        db=NULL;
    }
}

-(NSString*)error
{
    return @(sqlite3_errmsg(db));
}

-(void)dealloc
{
    [self close];
    [_databasePath release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStreamQLite(testing) 

+_chinookDB
{
    NSString *path=[[NSBundle bundleForClass:self] pathForResource:@"chinook" ofType:@"db"];
    MPWStreamQLite *db = [self open:path];
    MPWPListBuilder *builder=[MPWPListBuilder builder];
    db.builder = builder;
    return db;
}

+(void)testOpenChinookAndReadCorrectNumberOfArtists
{
    MPWStreamQLite *db=[self _chinookDB];
    [db query:@"select * from artists"];
    NSArray *artists=[db.builder result];
    INTEXPECT(artists.count, 275, @"number of artists");
}

+(void)testReadTracks
{
    MPWStreamQLite *db=[self _chinookDB];
    [db query:@"select * from tracks"];
    NSArray<NSDictionary*> *tracks=[db.builder result];
    INTEXPECT(tracks.count, 3503, @"number of tracks");
    IDEXPECT( tracks.lastObject[@"Composer"] , @"Philip Glass", @"composer of last track");
    IDEXPECT( tracks.lastObject[@"Name"] , @"Koyaanisqatsi", @"name of last track");
    IDEXPECT( tracks.firstObject[@"Composer"] , @"Angus Young, Malcolm Young, Brian Johnson", @"composer of first track");
}

+(instancetype)_testerDB
{
    MPWStreamQLite *db=[self memory];
    EXPECTNOTNIL(db, @"got a db");
    [db query:@"CREATE TABLE Tester (a INT,b INT, c VARCHAR(50))"];
    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    INTEXPECT([db.builder.result count],0,@"no results");
    return db;
}

+(void)testInsert
{
    MPWStreamQLite *db=[self _testerDB];
    MPWSQLTable *writer=[db tables][@"Tester"];
    [writer beginDictionary];
    [writer writeInteger:2 forKey:@"a"];
    [writer writeInteger:3 forKey:@"b"];
    [writer writeObject:@"hello" forKey:@"c"];
    [writer endDictionary];

    [writer beginDictionary];
    [writer writeObject:@(4) forKey:@"a"];
    [writer writeInteger:5 forKey:@"b"];
    [writer writeObject:@"world" forKey:@"c"];
    [writer endDictionary];

    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    NSArray<NSDictionary*> *result=db.builder.result;
    INTEXPECT(result.count,2,@"number of rows");
    IDEXPECT(result.firstObject[@"a"],@(2),@"first.a");
    IDEXPECT(result.firstObject[@"b"],@(3),@"first.b");
    IDEXPECT(result.firstObject[@"c"],@"hello",@"first.c");
    IDEXPECT(result.lastObject[@"a"],@(4),@"last.a");
    IDEXPECT(result.lastObject[@"b"],@(5),@"last.b");
    IDEXPECT(result.lastObject[@"c"],@"world",@"last.c");
}

+(void)testInsertDict
{
    MPWStreamQLite *db=[self _testerDB];
    MPWSQLTable *writer=[db tables][@"Tester"];

    [writer writeObject:@{ @"a": @(2), @"b": @(4), @"c": @"More"  }];

    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    NSArray<NSDictionary*> *result=db.builder.result;
    INTEXPECT(result.count,1,@"results");
    IDEXPECT(result.firstObject[@"a"],@(2),@"first.a");
    IDEXPECT(result.firstObject[@"b"],@(4),@"first.b");
    IDEXPECT(result.firstObject[@"c"],@"More",@"first.c");
}

+(void)testQueryTableNames
{
    MPWStreamQLite *db=[self _chinookDB];
    NSArray *tableNames = [db dbTableNames];
    INTEXPECT( tableNames.count, 13, @"number of tables" );
    IDEXPECT( [tableNames componentsJoinedByString:@","],@"albums,sqlite_sequence,artists,customers,employees,genres,invoices,invoice_items,media_types,playlists,playlist_track,tracks,sqlite_stat1",@"tables");
}

+(void)testGetTables
{
    MPWStreamQLite *db=[self _chinookDB];
    [db open];
    NSDictionary<NSString*,MPWSQLTable*> *tables=[db getTables];
    INTEXPECT(tables.count, 13, @"number of tables");
    MPWSQLTable *albums=tables[@"albums"];
    IDEXPECT( [albums name],@"albums",@"name of first table");
    NSArray *albumsScheme=albums.schema;
    INTEXPECT([albumsScheme count], 3, @"number of columns");
}

+(NSArray*)testSelectors
{
   return @[
       @"testOpenChinookAndReadCorrectNumberOfArtists",
       @"testReadTracks",
       @"testInsert",
       @"testInsertDict",
       @"testQueryTableNames",
       @"testGetTables",
			];
}

@end





