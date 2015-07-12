//
//  HYExecuter.m
//  Hydra
//
//  Created by  Na Tae Hyun on 12. 5. 2..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYQuery.h"
#import "HYResult.h"
#import "HYAsyncTask.h"
#import "HYExecuter.h"
#import "HYWorker.h"
#import "Hydra.h"


@implementation HYExecuter

@synthesize employedWorker = _employedWorker;
@dynamic resultDict;

- (id) init
{
	if( (self = [super init]) != nil ) {
		if( [[self name] length] <= 0 ) {
			[self release];
			return nil;
		}
		if( (_resultDict = [[NSMutableDictionary alloc] init]) == nil ) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[_resultDict release];
	
	[super dealloc];
}

- (BOOL) executeWithQuery: (id)anQuery
{
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	return [self calledExecutingWithQuery: anQuery];
}

- (BOOL) cancelWithQuery: (id)anQuery
{
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	return [self calledCancelingWithQuery: anQuery];
}

- (BOOL) skipWithQuery: (id)anQuery
{
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	return [self calledSkippingWithQuery: anQuery];
}

- (void) doCustomPostNotificationForResultDict: (NSDictionary *)resultDict
{
	NSString	*name;
	id			anResult;
	
	for( name in resultDict ) {
		anResult = [resultDict objectForKey: name];
		if( [anResult isKindOfClass: [HYResult class]] == YES ) {
			[self calledCustomPostNotificationForResult: anResult];
		}
	}
}

- (BOOL) restoreQueryToQueue: (id)anQuery
{
	if( [_employedWorker respondsToSelector: @selector(pushQueryToFront:)] == NO ) {
		return NO;
	}
	
	[_employedWorker pushQueryToFront: anQuery];
	
	return YES;
}

- (void) storeResult: (id)anResult
{
	if( [anResult isKindOfClass: [HYResult class]] == NO ) {
		return;
	}
	
	[_resultDict setObject: anResult forKey: [anResult name]];
}

- (void) removeResultForName: (NSString *)resultName
{
	if( [resultName length] <= 0 ) {
		return;
	}
	
	[_resultDict removeObjectForKey: resultName];
}

- (void) clearAllResults
{
	[_resultDict removeAllObjects];
}

- (id) workerCacheDataForKey: (NSString *)key
{
	if( [_employedWorker respondsToSelector: @selector(cacheDataForKey:)] == NO ) {
		return nil;
	}
	
	return [_employedWorker cacheDataForKey: key];
}

- (BOOL) setWorkerCacheData: (id)anData forKey: (NSString *)key
{
	if( [_employedWorker respondsToSelector: @selector(setCacheData:forKey:)] == NO ) {
		return NO;
	}
	
	return [_employedWorker setCacheData: anData forKey: key];
}

- (void) removeWorkerCacheDataForKey: (NSString *)key
{
	if( [_employedWorker respondsToSelector: @selector(removeCacheDataForKey:)] == NO ) {
		return;
	}
	
	[_employedWorker removeCacheDataForKey: key];
}

- (void) removeAllWorkerCacheData
{
	if( [_employedWorker respondsToSelector: @selector(removeAllCacheData)] == NO ) {
		return;
	}
	
	[_employedWorker removeAllCacheData];
}

- (id) sharedDataForKey: (NSString *)key
{
	id		employedHydra;
	
	if( [_employedWorker respondsToSelector: @selector(delegate)] == NO ) {
		return 0;
	}
	employedHydra = [_employedWorker delegate];
	
	if( [employedHydra respondsToSelector: @selector(sharedDataForKey:)] == NO ) {
		return 0;
	}
	
	return [employedHydra sharedDataForKey: key];
}

- (BOOL) setSharedData: (id)anData forKey: (NSString *)key
{
	id		employedHydra;
	
	if( [_employedWorker respondsToSelector: @selector(delegate)] == NO ) {
		return NO;
	}
	employedHydra = [_employedWorker delegate];
	
	if( [employedHydra respondsToSelector: @selector(setSharedData:forKey:)] == NO ) {
		return NO;
	}
	
	return [employedHydra setSharedData: anData forKey: key];
}

- (void) removeSharedDataForKey: (NSString *)key
{
	id		employedHydra;
	
	if( [_employedWorker respondsToSelector: @selector(delegate)] == NO ) {
		return;
	}
	employedHydra = [_employedWorker delegate];
	
	if( [employedHydra respondsToSelector: @selector(removeSharedDataForKey:)] == NO ) {
		return;
	}
	
	[employedHydra removeSharedDataForKey: key];
}

- (void) removeAllSharedData
{
	id		employedHydra;
	
	if( [_employedWorker respondsToSelector: @selector(delegate)] == NO ) {
		return;
	}
	employedHydra = [_employedWorker delegate];
	
	if( [employedHydra respondsToSelector: @selector(removeAllSharedData)] == NO ) {
		return;
	}
	
	[employedHydra removeAllSharedData];
}

- (NSString *) nameOfEmployedWorker
{
	if( [_employedWorker respondsToSelector: @selector(name)] == NO ) {
		return nil;
	}
	
	return [_employedWorker name];
}

- (NSString *) nameOfEmployedHydra
{
	id		employedHydra;
	
	if( [_employedWorker respondsToSelector: @selector(delegate)] == NO ) {
		return nil;
	}
	employedHydra = [_employedWorker delegate];
	
	if( [employedHydra respondsToSelector: @selector(name)] == NO ) {
		return nil;
	}
	
	return [employedHydra name];
}

- (BOOL) bindAsyncTask: (id)anAsyncTask
{
	id		employedHydra;
	
	if( [anAsyncTask isKindOfClass: [HYAsyncTask class]] == NO ) {
		return NO;
	}
	
	if( [_employedWorker respondsToSelector: @selector(delegate)] == NO ) {
		return NO;
	}
	employedHydra = [_employedWorker delegate];
	
	if( [employedHydra respondsToSelector: @selector(bindAsyncTask:)] == NO ) {
		return NO;
	}
	
	return [employedHydra bindAsyncTask: anAsyncTask];
}

- (BOOL) canIKeepGoingWithQuery: (id)anQuery
{
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	if( [anQuery canceled] == YES ) {
		[self cancelWithQuery: anQuery];
		return NO;
	}
	
	if( [anQuery paused] == YES ) {
		if( [self queryWillPause: anQuery] == YES ) {
			[self restoreQueryToQueue: anQuery];
		}
		return NO;
	}
	
	return YES;
}

- (NSDictionary *) resultDict
{
	return [NSDictionary dictionaryWithDictionary: _resultDict];
}

- (NSString *) name
{
	// you must override me :)
	return nil;
}

- (NSString *) brief
{
	// override me, if need :)
	return nil;
}

- (NSString *) customDataDescription
{
	// override me, if need :)
	return nil;
}

- (BOOL) shouldSkipExecutingWithQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (BOOL) calledExecutingWithQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (BOOL) calledCancelingWithQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (BOOL) calledSkippingWithQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (id) resultForExpiredQuery: (id)anQuery
{
	// override me, if need :)
	
	HYResult		*anResult;
	
	if( (anResult = [HYResult resultWithName: [anQuery executerName]]) == nil ) {
		return nil;
	}
	
	[anResult setIssuedIdOfQuery: [anQuery issuedId]];
	[anResult markAutomaticallyMadeByTimeout];
	
	return anResult;
}

- (BOOL) useCustomPostNotification
{
	// override me, if need :)
	return NO;
}

- (void) calledCustomPostNotificationForResult: (id)anResult
{
	// override me, if need :)
}

- (BOOL) queryWillPause: (id)anQuery
{
	// override me, if need :)
	return YES;
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*brief;
	NSString	*name;
	NSString	*dataDescription;
	
	desc = [NSString stringWithFormat: @"<executer name=\"%@\">", [self name]];
	
	if( (brief = [self brief]) != nil ) {
		desc = [desc stringByAppendingFormat: @"<brief>%@</brief>", brief];
	}
	if( [_employedWorker respondsToSelector: @selector(name)] == YES ) {
		if( (name = [_employedWorker name]) != nil ) {
			desc = [desc stringByAppendingFormat: @"<employed name=\"%@\"/>", name];
		}
	}
	if( (dataDescription = [self customDataDescription]) != nil ) {
		desc = [desc stringByAppendingFormat: @"<custom_data_description>%@</custom_data_description>", dataDescription];
	}
	desc = [desc stringByAppendingString: @"</executer>"];
	
	return desc;
}

@end
