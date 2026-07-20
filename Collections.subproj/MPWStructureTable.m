//
//  MPWStructureTable.m
//  MPWFoundation
//

#import "MPWStructureTable.h"
#import "MPWTableColumn.h"
#import "MPWStructureDefinition.h"
#import "MPWVariableDefinition.h"
#import "MPWTypeDefinition.h"
#import "MPWRESTOperation.h"

NSString * const MPWPresentationControlKey = @"control";
NSString * const MPWPresentationAllowedValuesKey = @"allowedValues";
NSString * const MPWPresentationDisplayValuesKey = @"displayValues";
NSString * const MPWPresentationPlaceholderKey = @"placeholder";
NSString * const MPWPresentationActionKey = @"action";
NSString * const MPWPresentationDestructiveKey = @"destructive";
NSString * const MPWPresentationStyleKey = @"presentationStyle";

@interface MPWStructureLabelColumn ()
@property (nonatomic,retain) NSArray<MPWVariableDefinition*> *fields;
@end

@interface MPWStructureValueColumn ()
@property (nonatomic,retain) NSArray<MPWVariableDefinition*> *fields;
@property (nonatomic,retain) id <MPWStorage> store;
@end

@interface MPWStructureComponentTable : MPWTable
@property (nonatomic,retain) NSArray<MPWVariableDefinition*> *fields;
@property (nonatomic,retain) id <MPWStorage> store;
@end

@implementation MPWStructureLabelColumn

-(id)objectAtIndex:(NSUInteger)index
{
    return index < self.fields.count ? self.fields[index].title : nil;
}

-(NSDictionary*)presentationMetadataAtIndex:(NSUInteger)index
{
    return @{ MPWPresentationControlKey: @"label" };
}

-(void)dealloc
{
    [_fields release];
    [super dealloc];
}

@end

static NSArray *MPWStructureColumns(NSArray<MPWVariableDefinition*> *fields, id<MPWStorage> store)
{
    MPWStructureLabelColumn *label=[[[MPWStructureLabelColumn alloc] init] autorelease];
    label.key=@"label";
    label.title=@"";
    label.type=[MPWTypeDefinition idType];
    label.editable=NO;
    label.visible=YES;
    label.fields=fields;

    MPWStructureValueColumn *value=[[[MPWStructureValueColumn alloc] init] autorelease];
    value.key=@"value";
    value.title=@"";
    value.type=[MPWTypeDefinition idType];
    value.editable=YES;
    value.visible=YES;
    value.fields=fields;
    value.store=store;
    return @[ label, value ];
}

static BOOL MPWStructureFieldIsVisible(MPWVariableDefinition *field)
{
    return field.type.visible && ![field.presentationMetadata[@"hidden"] boolValue];
}

static void MPWAppendVisibleLeafFields(MPWStructureDefinition *definition, NSMutableArray *result)
{
    for (MPWVariableDefinition *field in definition.fields) {
        if (!MPWStructureFieldIsVisible(field)) { continue; }
        if ([field.type isKindOfClass:[MPWStructureDefinition class]]) {
            MPWAppendVisibleLeafFields((MPWStructureDefinition*)field.type,result);
        } else {
            [result addObject:field];
        }
    }
}

static NSArray *MPWVisibleLeafFields(MPWStructureDefinition *definition)
{
    NSMutableArray *result=[NSMutableArray array];
    MPWAppendVisibleLeafFields(definition,result);
    return result;
}

@implementation MPWStructureComponentTable

-(NSUInteger)count { return self.fields.count; }

-(id)objectAtIndex:(NSUInteger)index
{
    return index < self.fields.count ? self.fields[index] : nil;
}

-(void)rowsDo:(void (^)(NSNumber *))block
{
    for (NSUInteger index=0; index<self.count; index++) { block(@(index)); }
}

-(void)dealloc
{
    [_fields release];
    [_store release];
    [super dealloc];
}

@end

@implementation MPWStructureValueColumn

-(MPWVariableDefinition*)fieldAtIndex:(NSUInteger)index
{
    return index < self.fields.count ? self.fields[index] : nil;
}

-(id)objectAtIndex:(NSUInteger)index
{
    MPWVariableDefinition *field=[self fieldAtIndex:index];
    return field ? [self.store at:[self.store referenceForPath:field.name]] : nil;
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
    MPWVariableDefinition *field=[self fieldAtIndex:index];
    if (field && [self isEditableAtIndex:index]) {
        [self.store at:[self.store referenceForPath:field.name] put:object];
    }
}

-(MPWTypeDefinition*)typeAtIndex:(NSUInteger)index
{
    return [self fieldAtIndex:index].type;
}

-(BOOL)isEditableAtIndex:(NSUInteger)index
{
    MPWVariableDefinition *field=[self fieldAtIndex:index];
    return field && (field.operations & MPWRESTVerbsWrite) != 0;
}

-(NSDictionary*)presentationMetadataAtIndex:(NSUInteger)index
{
    MPWVariableDefinition *field=[self fieldAtIndex:index];
    NSDictionary *metadata=field.presentationMetadata ?: @{};
    // A field's allowed values live on the field itself (the `values`
    // mechanism).  Surface them through the presentation metadata so presenters
    // need only one path to multi-valued fields.
    if ( field.values.count && !metadata[MPWPresentationAllowedValuesKey] ) {
        NSMutableDictionary *merged=[[metadata mutableCopy] autorelease];
        merged[MPWPresentationAllowedValuesKey]=field.values;
        metadata=merged;
    }
    return metadata;
}

-(void)dealloc
{
    [_fields release];
    [_store release];
    [super dealloc];
}

@end

@interface MPWStructureTable ()
@property (nonatomic,retain) MPWStructureDefinition *structureDefinition;
@property (nonatomic,retain) id <MPWStorage> store;
@property (nonatomic,retain) NSArray<MPWVariableDefinition*> *visibleFields;
@end

@implementation MPWStructureTable

+(instancetype)tableWithStructureDefinition:(MPWStructureDefinition*)definition store:(id<MPWStorage>)store
{
    return [[[[self class] alloc] initWithStructureDefinition:definition store:store] autorelease];
}

-(instancetype)initWithStructureDefinition:(MPWStructureDefinition*)definition store:(id<MPWStorage>)store
{
    self=[super init];
    if (self) {
        self.structureDefinition=definition;
        self.store=store;
        self.visibleFields=MPWVisibleLeafFields(definition);
        self.presentationMetadata=@{ MPWPresentationStyleKey: @"form" };
        self.columns=MPWStructureColumns(self.visibleFields, self.store);
        [self buildComponentTables];
    }
    return self;
}

-(MPWTable*)componentWithDefinition:(MPWStructureDefinition*)definition title:(NSString*)title
{
    MPWStructureComponentTable *component=[[[MPWStructureComponentTable alloc] init] autorelease];
    NSArray *fields=MPWVisibleLeafFields(definition);
    component.fields=fields;
    component.store=self.store;
    component.columns=MPWStructureColumns(fields, self.store);
    component.itemStructure=definition;
    component.tableIdentifier=title ?: definition.name;
    return component;
}

-(void)addFlatFields:(NSArray*)fields toComponents:(NSMutableArray*)components
{
    if (!fields.count) { return; }
    MPWStructureDefinition *flat=[MPWStructureDefinition structureWithName:@"" fields:fields];
    [components addObject:[self componentWithDefinition:flat title:@""]];
}

-(void)buildComponentTables
{
    NSMutableArray *components=[NSMutableArray array];
    BOOL containsNestedStructure=NO;
    for (MPWVariableDefinition *field in self.structureDefinition.fields) {
        if (MPWStructureFieldIsVisible(field) && [field.type isKindOfClass:[MPWStructureDefinition class]]) {
            containsNestedStructure=YES;
            break;
        }
    }
    if (!containsNestedStructure) {
        [components addObject:[self componentWithDefinition:self.structureDefinition title:@""]];
        self.componentTables=components;
        return;
    }

    NSMutableArray *flatFields=[NSMutableArray array];
    for (MPWVariableDefinition *field in self.structureDefinition.fields) {
        if (!MPWStructureFieldIsVisible(field)) { continue; }
        if ([field.type isKindOfClass:[MPWStructureDefinition class]]) {
            [self addFlatFields:flatFields toComponents:components];
            [flatFields removeAllObjects];
            [components addObject:[self componentWithDefinition:(MPWStructureDefinition*)field.type
                                                           title:field.title]];
        } else {
            [flatFields addObject:field];
        }
    }
    [self addFlatFields:flatFields toComponents:components];
    self.componentTables=components;
}

-(void)dealloc
{
    [_structureDefinition release];
    [_store release];
    [_visibleFields release];
    [super dealloc];
}

@end

#import <MPWFoundation/DebugMacros.h>
#import "MPWDictStore.h"

@interface MPWStructureTableTestStore : MPWRawDictStore
@property (nonatomic,assign) NSUInteger readCount;
@property (nonatomic,assign) NSUInteger writeCount;
@end

@implementation MPWStructureTableTestStore
-(id)at:(id<MPWIdentifying>)reference { self.readCount++; return [super at:reference]; }
-(void)at:(id<MPWIdentifying>)reference put:(id)object { self.writeCount++; [super at:reference put:object]; }
@end

@implementation MPWStructureTable (testing)

+(MPWStructureDefinition*)testDefinition
{
    MPWVariableDefinition *name=[[[MPWVariableDefinition alloc] initWithName:@"firstName" type:[MPWTypeDefinition idType]] autorelease];
    name.title=@"First name";
    name.operations=MPWRESTVerbsReadWrite;
    MPWVariableDefinition *enabled=[[[MPWVariableDefinition alloc] initWithName:@"enabled" type:[MPWTypeDefinition descriptorForObjcCode:'B']] autorelease];
    enabled.title=@"Enabled";
    enabled.operations=MPWRESTVerbsReadWrite;
    MPWVariableDefinition *notes=[[[MPWVariableDefinition alloc] initWithName:@"notes" type:[MPWTypeDefinition descriptorForTypeName:@"Text"]] autorelease];
    notes.title=@"Notes";
    notes.operations=MPWRESTVerbsRead;

    MPWStructureDefinition *identity=[MPWStructureDefinition structureWithName:@"Identity" fields:@[name]];
    MPWStructureDefinition *options=[MPWStructureDefinition structureWithName:@"Options" fields:@[enabled,notes]];
    options.documentation=@"Configuration options.";
    MPWVariableDefinition *identitySection=[[[MPWVariableDefinition alloc] initWithName:@"identity" type:identity] autorelease];
    identitySection.title=@"IDENTITY";
    MPWVariableDefinition *optionsSection=[[[MPWVariableDefinition alloc] initWithName:@"options" type:options] autorelease];
    optionsSection.title=@"OPTIONS";
    return [MPWStructureDefinition structureWithName:@"Example" fields:@[identitySection,optionsSection]];
}

+(MPWStructureTable*)testTable
{
    MPWStructureTableTestStore *store=[MPWStructureTableTestStore storeWithDictionary:[[@{ @"firstName": @"Ada", @"enabled": @YES } mutableCopy] autorelease]];
    return [self tableWithStructureDefinition:[self testDefinition] store:store];
}

+(void)testRowsAreVisibleFieldsInDefinitionOrder
{
    MPWStructureTable *table=[self testTable];
    INTEXPECT(table.count,3,@"one row per field");
    IDEXPECT([table objectAtIndex:0],table.visibleFields[0],@"row object is first leaf definition");
    IDEXPECT([table objectAtIndex:2],table.visibleFields[2],@"nested field ordering preserved");
}

+(void)testLabelAndValueColumnsProjectDefinitionAndStore
{
    MPWStructureTable *table=[self testTable];
    MPWTableColumn *label=table.columns[0];
    MPWStructureValueColumn *value=(id)table.columns[1];
    IDEXPECT([label objectAtIndex:0],@"First name",@"label comes from field title");
    IDEXPECT([value objectAtIndex:0],@"Ada",@"value is read from store");
    EXPECTTRUE([(MPWStructureTableTestStore*)table.store readCount] > 0,@"store received read");
    [value replaceObjectAtIndex:0 withObject:@"Grace"];
    IDEXPECT([value objectAtIndex:0],@"Grace",@"write updates represented value");
    INTEXPECT([(MPWStructureTableTestStore*)table.store writeCount],1,@"store received write");
}

+(void)testDeclaredTypesAndNilValuesRemainIndependent
{
    MPWStructureTable *table=[self testTable];
    MPWStructureValueColumn *value=(id)table.columns[1];
    EXPECTNIL([value objectAtIndex:2],@"notes value is nil");
    IDEXPECT([value typeAtIndex:0],[MPWTypeDefinition idType],@"string declared type");
    IDEXPECT([value typeAtIndex:1],[MPWTypeDefinition descriptorForObjcCode:'B'],@"boolean declared type");
    IDEXPECT([value typeAtIndex:2],[MPWTypeDefinition descriptorForTypeName:@"Text"],@"nil value keeps Text type");
}

+(void)testReadOnlyFieldRejectsWrite
{
    MPWStructureTable *table=[self testTable];
    MPWStructureValueColumn *value=(id)table.columns[1];
    NSUInteger before=[(MPWStructureTableTestStore*)table.store writeCount];
    [value replaceObjectAtIndex:2 withObject:@"should not write"];
    INTEXPECT([(MPWStructureTableTestStore*)table.store writeCount],before,@"read-only field does not write");
    EXPECTFALSE([value isEditableAtIndex:2],@"read-only metadata exposed per row");
}

+(void)testGenericStoreAndSections
{
    MPWStructureDefinition *definition=[self testDefinition];
    MPWRawDictStore *other=[MPWRawDictStore storeWithDictionary:[[@{ @"firstName": @"Lin" } mutableCopy] autorelease]];
    MPWStructureTable *table=[self tableWithStructureDefinition:definition store:other];
    IDEXPECT([table.columns[1] objectAtIndex:0],@"Lin",@"same definition works with another store");
    INTEXPECT(table.componentTables.count,2,@"nested structures produce component tables");
    INTEXPECT([table componentTableAtIndex:0].count,1,@"first component table");
    INTEXPECT([table componentTableAtIndex:1].count,2,@"second component table");
    IDEXPECT([table componentTableAtIndex:0].tableIdentifier,@"IDENTITY",@"member title names the component table");
    IDEXPECT([table componentTableAtIndex:0].itemStructure,
             definition.fields[0].type,@"component retains its nested structure definition");
    IDEXPECT([table componentTableAtIndex:1].itemStructure.documentation,
             @"Configuration options.",@"nested structure carries its own documentation");
}

+(void)testFlatDefinitionIsDegenerateComposite
{
    MPWVariableDefinition *field=[MPWVariableDefinition idWithName:@"value"];
    MPWStructureDefinition *definition=[MPWStructureDefinition structureWithName:@"Flat" fields:@[field]];
    MPWStructureTable *table=[self tableWithStructureDefinition:definition
                                                          store:[MPWRawDictStore storeWithDictionary:[NSMutableDictionary dictionary]]];
    INTEXPECT(table.componentTables.count,1,@"flat structure has one component");
    IDEXPECT([table componentTableAtIndex:0].itemStructure,definition,@"flat component is the root structure");
}

+(NSArray*)testSelectors
{
    return @[
        @"testRowsAreVisibleFieldsInDefinitionOrder",
        @"testLabelAndValueColumnsProjectDefinitionAndStore",
        @"testDeclaredTypesAndNilValuesRemainIndependent",
        @"testReadOnlyFieldRejectsWrite",
        @"testGenericStoreAndSections",
        @"testFlatDefinitionIsDegenerateComposite",
    ];
}

@end
