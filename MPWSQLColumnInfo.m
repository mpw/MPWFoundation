//
//  MPWSQLColumnInfo.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import "MPWSQLColumnInfo.h"

@implementation MPWSQLColumnInfo

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: name: '%@' type: '%@' %@ %@",self.class,self,self.name,self.type,self.pk ? @"PRIMARY KEY":@"",self.notnull ? @"NOTNULL":@""];
}

-(void)dealloc
{
    [_name release];
    [_type release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSQLColumnInfo(testing) 

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
