//
//  HYQuery.m
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYQuery.h"


int32_t			g_HYQuery_last_issuedId;


@interface HYQuery ()
{
    int32_t		_issuedIdOfAsyncTask;
}
@end


@implementation HYQuery

@dynamic issuedIdOfAsyncTask;

- (instancetype) init NS_UNAVAILABLE
{
	return nil;
}

- (instancetype) initWithWorkerName: (NSString *)workerName executerName: (NSString *)executerName;
{
	if( (self = [super init]) != nil ) {
		if( workerName.length <= 0 ) {
			return nil;
		}
		_workerName = workerName;
		if( executerName.length <= 0 ) {
			return nil;
		}
		_executerName = executerName;
		if( (_paramDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		_issuedId = OSAtomicIncrement32( &g_HYQuery_last_issuedId );
	}
	
	return self;
}

+ (HYQuery *) queryWithWorkerName: (NSString *)workerName executerName: (NSString *)executerName
{
	return [[HYQuery alloc] initWithWorkerName: workerName executerName: executerName];
}

- (id) parameterForKey: (NSString *)key
{
	if( key.length <= 0 ) {
		return nil;
	}
	
	return _paramDict[key];
}

- (void) setParameter: (id)anObject forKey: (NSString *)key
{
	if( (anObject == nil) || (key.length <= 0) ) {
		return;
	}
	
	_paramDict[key] = anObject;
}

- (void) setParametersFromDictionary: (NSDictionary *)dict
{
	if( dict.count <= 0 ) {
		return;
	}
	
	[_paramDict addEntriesFromDictionary: dict];
}

- (void) removeParameterForKey: (NSString *)key
{
	if( key.length <= 0 ) {
		return;
	}
	
	[_paramDict removeObjectForKey: key];
}

- (BOOL) setWaitingResultName: (NSString *)resultName withTimeoutInterval: (NSTimeInterval)timeoutInterval skipMeIfAlreadyWaiting: (BOOL)skipMeIfAlreadyWaiting
{
	if( (resultName.length <= 0) || (timeoutInterval <= 0.0) ) {
		return NO;
	}
	
	_waitingResultName = resultName;
	_waitingTimeoutInterval = timeoutInterval;
    _skipMeIfAlreadyWaiting = skipMeIfAlreadyWaiting;
	_haveWaitingResult = YES;
	
	return YES;
}

- (void) clearWaitingResult
{
	_waitingResultName = nil;
	_waitingTimeoutInterval = 0.0;
	_haveWaitingResult = NO;
}

- (int32_t) issuedIdOfAsyncTask
{
	return _issuedIdOfAsyncTask;
}

- (void) setIssuedIdOfAsyncTask: (int32_t)issuedIdOfAsyncTask
{
	_issuedIdOfAsyncTask = issuedIdOfAsyncTask;
	_haveAsyncTask = YES;
}

- (BOOL) isEqual: (id)anObject
{
	if( [anObject isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	return (self.issuedId == [anObject issuedId]);
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*key;
	id			anObject;
	
	desc = [NSString stringWithFormat: @"<query issuedid=\"%d\" worker=\"%@\" executer=\"%@\" paused=\"%@\" canceled=\"%@\">", _issuedId, _workerName, _executerName, @(_paused).stringValue, @(_canceled).stringValue];
	if( _paramDict.count > 0 ) {
		desc = [desc stringByAppendingString: @"<paramters>"];
		for( key in _paramDict ) {
			anObject = _paramDict[key];
			if( [anObject respondsToSelector: @selector(description)] == YES ) {
				desc = [desc stringByAppendingFormat: @"<parameter key=\"%@\" value=\"%@\"/>", key, anObject];
			} else {
				desc = [desc stringByAppendingFormat: @"<parameter key=\"%@\"/>", key];
			}
		}
		desc = [desc stringByAppendingString: @"</paramters>"];
	}
	if( _waitingResultName.length > 0 ) {
		desc = [desc stringByAppendingFormat: @"<waiting_result name=\"%@\" timeout=\"%lf\" skip=\"%@\"/>", _waitingResultName, _waitingTimeoutInterval, @(_skipMeIfAlreadyWaiting).stringValue];
	}
	if( _haveAsyncTask == YES ) {
		desc = [desc stringByAppendingFormat: @"<async_task issuedid=\"%d\"/>", _issuedIdOfAsyncTask];
	}
	desc = [desc stringByAppendingString: @"</query>"];
	
	return desc;
}

@end
