//
//  HYTrackingResultSet.m
//  Hydra
//
//  Created by  Na Tae Hyun on 12. 5. 11..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYResult.h"
#import "HYTrackingResultSet.h"


@implementation HYTrackingResultSet

@synthesize name = _name;
@dynamic resultDict;

- (id) init
{
	return nil;
}

- (id) initWithName: (NSString *)name
{
	if( (self = [super init]) != nil ) {
		if( [name length] <= 0 ) {
			[self release];
			return nil;
		}
		_name = [name retain];
		if( (_resultNameDict = [[NSMutableDictionary alloc] init]) == nil ) {
			[self release];
			return nil;
		}
		if( (_resultValueDict = [[NSMutableDictionary alloc] init]) == nil ) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[_name release];
	[_resultNameDict release];
	[_resultValueDict release];
	
	[super dealloc];
}

- (void) setResultNamesFromArray: (NSArray *)resultNames
{
	NSString	*resultName;
	
	[_resultNameDict removeAllObjects];
	[_resultValueDict removeAllObjects];
	
	if( [resultNames count] <= 0 ) {
		return;
	}
	
	for( resultName in resultNames ) {
		[self addResultName: resultName];
	}
}

- (BOOL) addResultName: (NSString *)resultName
{
	if( [resultName length] <= 0 ) {
		return NO;
	}
	
	if( [_resultNameDict objectForKey: resultName] != nil ) {
		return NO;
	}
	
	[_resultNameDict setObject: resultName forKey: resultName];
	
	return YES;
}

- (void) removeResultName: (NSString *)resultName
{
	if( [resultName length] <= 0 ) {
		return;
	}
	
	[_resultNameDict removeObjectForKey: resultName];
	[_resultValueDict removeObjectForKey: resultName];
}

- (BOOL) updateResult: (id)anResult
{
	if( [anResult isKindOfClass: [HYResult class]] == NO ) {
		return NO;
	}
	
	if( [_resultNameDict objectForKey: [anResult name]] == nil ) {
		return NO;
	}
	
	[_resultValueDict setObject: anResult forKey: [anResult name]];
	
	return YES;
}

- (void) clearResultForName: (NSString *)resultName
{
	if( [resultName length] <= 0 ) {
		return;
	}
	
	[_resultValueDict removeObjectForKey: resultName];
}

- (BOOL) refreshed
{
	if( [_resultNameDict count] <= 0 ) {
		return NO;
	}
	
	return ([_resultNameDict count] == [_resultValueDict count]);
}

- (void) touch
{
	[_resultValueDict removeAllObjects];
}

- (NSDictionary *) resultDict
{
	if( [self refreshed] == NO ) {
		return nil;
	}
	
	return [NSDictionary dictionaryWithDictionary: _resultValueDict];
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*key;
	
	desc = [NSString stringWithFormat: @"<tracking_resultset name=\"%@\">", _name];
	if( [_resultNameDict count] > 0 ) {
		for( key in _resultNameDict ) {
			desc = [desc stringByAppendingFormat: @"<tracking_result name=\"%@\"/>", key];
		}
	}
	desc = [desc stringByAppendingString: @"</tracking_resultset>"];
	
	return desc;
}

@end
