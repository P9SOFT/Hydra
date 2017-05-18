//
//  HYTrackingResultSet.m
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYResult.h"
#import "HYTrackingResultSet.h"


@interface HYTrackingResultSet ()

{
    NSString				*_name;
    NSMutableDictionary		*_resultNameDict;
    NSMutableDictionary		*_resultValueDict;
}

@end


@implementation HYTrackingResultSet

@synthesize name = _name;
@dynamic resultDict;

- (instancetype) init NS_UNAVAILABLE
{
	return nil;
}

- (instancetype) initWithName: (NSString *)name
{
	if( (self = [super init]) != nil ) {
		if( name.length <= 0 ) {
			return nil;
		}
		_name = name;
		if( (_resultNameDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_resultValueDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
	}
	
	return self;
}

- (void) setResultNamesFromArray: (NSArray *)resultNames
{
	NSString	*resultName;
	
	[_resultNameDict removeAllObjects];
	[_resultValueDict removeAllObjects];
	
	if( resultNames.count <= 0 ) {
		return;
	}
	
	for( resultName in resultNames ) {
		[self addResultName: resultName];
	}
}

- (BOOL) addResultName: (NSString *)resultName
{
	if( resultName.length <= 0 ) {
		return NO;
	}
	
	if( _resultNameDict[resultName] != nil ) {
		return NO;
	}
	
	_resultNameDict[resultName] = resultName;
	
	return YES;
}

- (void) removeResultName: (NSString *)resultName
{
	if( resultName.length <= 0 ) {
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
	
	if( _resultNameDict[[anResult name]] == nil ) {
		return NO;
	}
	
	_resultValueDict[[anResult name]] = anResult;
	
	return YES;
}

- (void) clearResultForName: (NSString *)resultName
{
	if( resultName.length <= 0 ) {
		return;
	}
	
	[_resultValueDict removeObjectForKey: resultName];
}

- (BOOL) refreshed
{
	if( _resultNameDict.count <= 0 ) {
		return NO;
	}
	
	return (_resultNameDict.count == _resultValueDict.count);
}

- (void) touch
{
	[_resultValueDict removeAllObjects];
}

- (NSDictionary *) resultDict
{
	if( self.refreshed == NO ) {
		return nil;
	}
	
	return [NSDictionary dictionaryWithDictionary: _resultValueDict];
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*key;
	
	desc = [NSString stringWithFormat: @"<tracking_resultset name=\"%@\">", _name];
	if( _resultNameDict.count > 0 ) {
		for( key in _resultNameDict ) {
			desc = [desc stringByAppendingFormat: @"<tracking_result name=\"%@\"/>", key];
		}
	}
	desc = [desc stringByAppendingString: @"</tracking_resultset>"];
	
	return desc;
}

@end
