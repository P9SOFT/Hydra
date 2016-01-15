//
//  HYResult.m
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYQuery.h"
#import "HYResult.h"


int32_t			g_HYResult_last_issuedId;


@implementation HYResult

@synthesize issuedId = _issuedId;
@synthesize issuedIdOfQuery = _issuedIdOfQuery;
@synthesize name = _name;
@synthesize paramDict = _paramDict;
@synthesize automaticallyMadeByTimeout = _automaticallyMadeByTimeout;

- (id) init
{
	return nil;
}

- (id) initWithName: (NSString *)name
{
	if( (self = [super init]) != nil ) {
		if( [name length] <= 0 ) {
			return nil;
		}
		_name = name;
		if( (_paramDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		_issuedId = OSAtomicIncrement32( &g_HYResult_last_issuedId );
	}
	
	return self;
}

+ (HYResult *) resultWithName: (NSString *)name
{
	return [[HYResult alloc] initWithName: name];
}

- (id) parameterForKey: (NSString *)key
{
	if( [key length] <= 0 ) {
		return nil;
	}
	
	return [_paramDict objectForKey: key];
}

- (void) setParameter: (id)anObject forKey: (NSString *)key
{
	if( (anObject == nil) || ([key length] <= 0) ) {
		return;
	}
	
	[_paramDict setObject: anObject forKey: key];
}

- (void) setParametersFromDictionary: (NSDictionary *)dict
{
	if( [dict count] <= 0 ) {
		return;
	}
	
	[_paramDict addEntriesFromDictionary: dict];
}

- (void) removeParameterForKey: (NSString *)key
{
	if( [key length] <= 0 ) {
		return;
	}
	
	[_paramDict removeObjectForKey: key];
}

- (void) markAutomaticallyMadeByTimeout
{
	_automaticallyMadeByTimeout = YES;
}

- (BOOL) isEqual: (id)anObject
{
	if( [anObject isKindOfClass: [HYResult class]] == NO ) {
		return NO;
	}
	
	return ([self issuedId] == [anObject issuedId]);
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*key;
	id			anObject;
	
	desc = [NSString stringWithFormat: @"<result issuedid=\"%d\" issuedid_of_query=\"%d\" name=\"%@\">", _issuedId, _issuedIdOfQuery, _name];
	if( [_paramDict count] > 0 ) {
		desc = [desc stringByAppendingString: @"<paramters>"];
		for( key in _paramDict ) {
			anObject = [_paramDict objectForKey: key];
			if( [anObject respondsToSelector: @selector(description)] == YES ) {
				desc = [desc stringByAppendingFormat: @"<parameter key=\"%@\" value=\"%@\"/>", key, anObject];
			} else {
				desc = [desc stringByAppendingFormat: @"<parameter key=\"%@\"/>", key];
			}
		}
		desc = [desc stringByAppendingString: @"</paramters>"];
	}
	desc = [desc stringByAppendingString: @"</result>"];
	
	return desc;
}

@end
