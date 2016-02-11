//
//  Hydra.m
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "Hydra.h"


Hydra			*g_defaultHydra;


@interface Hydra( HydraPrivate )

- (id) initWithName: (NSString *)name;
- (void) postNotificationMigrationStatus: (HydraNotificationCode)status suggestedNumber: (NSUInteger)suggestedNumber referenceNumber: (NSUInteger)referenceNumber thread: (BOOL)thread;
- (void) postNotificationWithParamDict: (NSDictionary *)paramDict;
- (void) stepMigration: (id)migration;
- (void) updateTrackingResultSetAndNotifyIfNeed: (id)anResult;
- (BOOL) setWaitingResultWithQuery: (id)anQuery;
- (void) timerForWaitingResultTimeout: (NSTimer *)anTimer;
- (void) clearResultAtWaitings: (id)anResult;
- (BOOL) setLimiterWithCount: (NSUInteger)count forName: (NSString *)name;
- (BOOL) holdLimiterWithaAsyncTask: (id)anAsyncTask forName: (NSString *)name;
- (id) throwawayLimiterForName: (NSString *)name;
- (BOOL) matchingAsyncTask: (id)anAsyncTask withQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName;
- (void) pauseAsyncTaskWithQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName;
- (void) resumeAsyncTaskWithQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName;
- (void) resumeAllAsyncTaskForMadeByQuery;
- (void) unbindAsyncTaskWithQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName;
- (void) unbindAllAsyncTasksForMadeByQuery;

@end


@implementation Hydra

@synthesize name = _name;

+ (Hydra *) defaultHydra
{
	@synchronized( self ) {
		if( g_defaultHydra == nil ) {
			g_defaultHydra = [[Hydra alloc] initWithName: kHydraDefaultName];
		}
	}
	
	return g_defaultHydra;
}

+ (void) destroyDefaultHydra
{
	@synchronized( self ) {
		g_defaultHydra = nil;
	}
}

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
		if( (_workerDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_sharedDataDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_lockForSharedDataDict = [[NSLock alloc] init]) == nil ) {
			return nil;
		}
		if( (_trackingResultSets = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_lockForTrackingResultSets = [[NSLock alloc] init]) == nil ) {
			return nil;
		}
		if( (_waitingResults = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_lockForWaitingResults = [[NSLock alloc] init]) == nil ) {
			return nil;
		}
		if( (_asyncTaskDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_asyncTaskLimiterDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_asyncTaskLimiterPoolDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_lockForAsyncTaskDict = [[NSLock alloc] init]) == nil ) {
			return nil;
		}
	}
	
	return self;
}

- (BOOL) doMigration: (id)migration waitUntilDone: (BOOL)waitUntilDone
{
	if( [migration isKindOfClass: [HYMigrator class]] == NO ) {
		return NO;
	}
	
	if( waitUntilDone == NO ) {
		[migration setUseBackgroundThread: YES];
		[self performSelectorInBackground: @selector(stepMigration:) withObject: migration];
	} else {
		[self stepMigration: migration];
	}
	
	return YES;
}

- (BOOL) addCommonWorker
{
    return [self addNormalWorkerForName: HydraCommonWorkerName];
}

- (BOOL) addNormalWorkerForName: (NSString *)name
{
    return [self addWorker:[[HYWorker alloc] initWithName: name]];
}

- (BOOL) addWorker: (id)anWorker
{
	if( [anWorker isKindOfClass: [HYWorker class]] == NO ) {
		return NO;
	}
	
	if( [_workerDict objectForKey: [anWorker name]] != nil ) {
		return NO;
	}
	
	[(HYWorker *)anWorker setDelegate: self];
	[_workerDict setObject: anWorker forKey: [anWorker name]];
	
	return YES;
}

- (void) removeWorkerForName: (NSString *)name
{
	if( [name length] <= 0 ) {
		return;
	}
		
	[_workerDict removeObjectForKey: name];
}

- (id) workerForName: (NSString *)name
{
	if( [name length] <= 0 ) {
		return nil;
	}
	
	return [_workerDict objectForKey: name];
}

- (void) startAllWorkers
{
	NSString		*name;
	id				anWorker;
	
	for( name in _workerDict ) {
		anWorker = [_workerDict objectForKey: name];
		if( [anWorker isRunning] == NO ) {
			[anWorker startWorker];
		}
	}
}

- (void) startWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( [name length] <= 0 ) {
		return;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) != nil ) {
		if( [anWorker isRunning] == NO ) {
			[anWorker startWorker];
		}
	}
}

- (void) pauseAllWorkers
{
	NSString		*name;
	id				anWorker;
	
	for( name in _workerDict ) {
		anWorker = [_workerDict objectForKey: name];
		if( [anWorker isRunning] == YES ) {
			[anWorker pauseWorker];
		}
	}
}

- (void) pauseWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( [name length] <= 0 ) {
		return;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) != nil ) {
		if( [anWorker isRunning] == YES ) {
			[anWorker pauseWorker];
		}
	}
}

- (void) resumeAllWorkers
{
	NSString		*name;
	id				anWorker;
	
	for( name in _workerDict ) {
		anWorker = [_workerDict objectForKey: name];
		if( [anWorker isPaused] == YES ) {
			[anWorker resumeWorker];
		}
	}
}

- (void) resumeWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( [name length] <= 0 ) {
		return;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) != nil ) {
		if( [anWorker isPaused] == YES ) {
			[anWorker resumeWorker];
		}
	}
}

- (void) stopAllWorkers
{
	NSString		*name;
	id				anWorker;
	
	for( name in _workerDict ) {
		anWorker = [_workerDict objectForKey: name];
		if( [anWorker isStarted] == YES ) {
			[anWorker stopWorker];
		}
	}
}

- (void) stopWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( [name length] <= 0 ) {
		return;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) != nil ) {
		if( [anWorker isStarted] == YES ) {
			[anWorker stopWorker];
		}
	}
}

- (BOOL) pushQuery: (id)anQuery
{
	HYWorker		*worker;
	
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	if( (worker = [_workerDict objectForKey: [anQuery workerName]]) == nil ) {
		return NO;
	}
	
	if( [anQuery haveWaitingResult] == YES ) {
		if( [self setWaitingResultWithQuery: anQuery] == NO ) {
            return YES;
        }
	}
	
	return [worker pushQuery: anQuery];
}

- (void) pauseQueryForIssuedId: (int32_t)issuedId
{
	NSString		*workerName;
	
	for( workerName in _workerDict ) {
		[[_workerDict objectForKey: workerName] pauseQueryForIssuedId: issuedId];
	}
	
	[self pauseAsyncTaskWithQueryIssuedId: issuedId workerName: nil executorName: nil];
}

- (void) pauseAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName
{
	if( ([executorName length] <= 0) || ([workerName length] <= 0) ) {
		return;
	}
	
	[[_workerDict objectForKey: workerName] pauseAllQueriesForExecutorName: executorName];
	
	[self pauseAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: executorName];
}

- (void) resumeQueryForIssuedId: (int32_t)issuedId
{
	NSString		*workerName;
	
	for( workerName in _workerDict ) {
		[[_workerDict objectForKey: workerName] resumeQueryForIssuedId: issuedId];
	}
	
	[self resumeAsyncTaskWithQueryIssuedId: issuedId workerName: nil executorName: nil];
}

- (void) resumeAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName
{
	if( ([executorName length] <= 0) || ([workerName length] <= 0) ) {
		return;
	}
	
	[[_workerDict objectForKey: workerName] resumeAllQueriesForExecutorName: executorName];
	
	[self resumeAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: executorName];
}

- (void) resumeAllQueries
{
	NSString	*workerName;
	id			anWorker;
	
	for( workerName in _workerDict ) {
		anWorker = [_workerDict objectForKey: workerName];
		[anWorker resumeAllQueries];
	}
	
	[self resumeAllAsyncTaskForMadeByQuery];
}

- (void) cancelQueryForIssuedId: (int32_t)issuedId
{
	NSString		*workerName;
	
	for( workerName in _workerDict ) {
		[[_workerDict objectForKey: workerName] cancelQueryForIssuedId: issuedId];
	}
	
	[self unbindAsyncTaskWithQueryIssuedId: issuedId workerName: nil executorName: nil];
}

- (void) cancelAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName
{
	if( ([executorName length] <= 0) || ([workerName length] <= 0) ) {
		return;
	}
	
	[[_workerDict objectForKey: workerName] cancelAllQueriesForExecutorName: executorName];
	
	[self unbindAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: executorName];
}

- (void) cancelAllQueriesForWorkerName: (NSString *)workerName
{
	if( [workerName length] <= 0 ) {
		return;
	}
	
	[[_workerDict objectForKey: workerName] cancelAllQueries];
	
	[self unbindAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: nil];
}

- (void) cancelAllQueries
{
	NSString	*workerName;
	id			anWorker;
	
	for( workerName in _workerDict ) {
		anWorker = [_workerDict objectForKey: workerName];
		[anWorker cancelAllQueries];
	}
	
	[self unbindAllAsyncTasksForMadeByQuery];
}

- (BOOL) setTrackingResultSet: (id)anTrackingResultSet
{
	if( [anTrackingResultSet isKindOfClass: [HYTrackingResultSet class]] == NO ) {
		return NO;
	}
	
	if( [_trackingResultSets objectForKey: [anTrackingResultSet name]] != nil ) {
		return NO;
	}
	
	[_lockForTrackingResultSets lock];
	
	[_trackingResultSets setObject: anTrackingResultSet forKey: [anTrackingResultSet name]];
	
	[_lockForTrackingResultSets unlock];
	
	return YES;
}

- (void) removeTrackingResultSetForName: (NSString *)name
{
	if( [name length] <= 0 ) {
		return;
	}
	
	[_lockForTrackingResultSets lock];
	
	[_trackingResultSets removeObjectForKey: name];
	
	[_lockForTrackingResultSets unlock];
}

- (id) cacheDataAtWorker: (NSString *)name forKey: (NSString *)key
{
	id		anWorker;
	
	if( ([name length] <= 0) || ([key length] <= 0) ) {
		return nil;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) == nil ) {
		return nil;
	}
	
	return [anWorker cacheDataForKey: key];
}

- (BOOL) setCacheData: (id)anData atWoker: (NSString *)name forKey: (NSString *)key
{
	id		anWorker;
	
	if( ([name length] <= 0) || ([key length] <= 0) ) {
		return NO;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) == nil ) {
		return NO;
	}
	
	return [anWorker setCacheData: anData forKey: key];
}

- (void) removeCacheDataAtWorker: (NSString *)name forKey: (NSString *)key
{
	id		anWorker;
	
	if( ([name length] <= 0) || ([key length] <= 0) ) {
		return;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) == nil ) {
		return;
	}
	
	[anWorker removeCacheDataForKey: key];
}

- (void) removeAllCacheDataAtWorker: (NSString *)name
{
	id		anWorker;
	
	if( [name length] <= 0 ) {
		return;
	}
	
	if( (anWorker = [_workerDict objectForKey: name]) == nil ) {
		return;
	}
	
	[anWorker removeAllCacheData];
}

- (id) sharedDataForKey: (NSString *)key
{
	id		anData;
	
	if( [key length] <= 0 ) {
		return nil;
	}
	
	[_lockForSharedDataDict lock];
	
	anData = [_sharedDataDict objectForKey: key];
	
	[_lockForSharedDataDict unlock];
	
	return anData;
}

- (BOOL) setSharedData: (id)anData forKey: (NSString *)key
{
	if( (anData == nil) || ([key length] <= 0) ) {
		return NO;
	}
	
	[_lockForSharedDataDict lock];
	
	[_sharedDataDict setObject: anData forKey: key];
	
	[_lockForSharedDataDict unlock];
	
	return YES;
}

- (void) removeSharedDataForKey: (NSString *)key
{
	if( [key length] <= 0 ) {
		return;
	}
	
	[_lockForSharedDataDict lock];
	
	[_sharedDataDict removeObjectForKey: key];
	
	[_lockForSharedDataDict unlock];
}

- (void) removeAllSharedData
{
	[_lockForSharedDataDict lock];
	
	[_sharedDataDict removeAllObjects];
	
	[_lockForSharedDataDict unlock];
}

- (BOOL) setLimiterWithCount: (NSUInteger)count forName: (NSString *)name
{
	NSMutableArray		*pair;
	NSMutableArray		*pool;
	BOOL				set;
	
	if( (count <= 0) || [name length] <= 0 ) {
		return NO;
	}
	
	set = NO;
		
	if( (pair = [_asyncTaskLimiterDict objectForKey: name]) != nil ) {
		if( [[pair objectAtIndex: 0] unsignedIntegerValue] != count ) {
			[pair removeObjectAtIndex: 0];
			[pair insertObject: [NSNumber numberWithUnsignedInteger: count] atIndex: 0];
		}
		set = YES;
	} else {
		if( (pair = [[NSMutableArray alloc] init]) != nil ) {
			if( (pool = [[NSMutableArray alloc] init]) != nil ) {
				[pair addObject: [NSNumber numberWithUnsignedInteger: count]];
				[pair addObject: [NSNumber numberWithUnsignedInteger: 0]];
				[_asyncTaskLimiterDict setObject: pair forKey: name];
				[_asyncTaskLimiterPoolDict setObject: pool forKey: name];
				set = YES;
			}
		}
	}
    
	return set;
}

- (BOOL) holdLimiterWithaAsyncTask: (id)anAsyncTask forName: (NSString *)name
{
	NSMutableArray		*pair;
	NSMutableArray		*pool;
	NSUInteger			used, limit;
	BOOL				hold;
	
	if( [name length] <= 0 ) {
		return NO;
	}
	
	if( (pair = [_asyncTaskLimiterDict objectForKey: name]) == nil ) {
		return NO;
	}
	
	hold = NO;
	limit = [[pair objectAtIndex: 0] unsignedIntegerValue];
	used = [[pair objectAtIndex: 1] unsignedIntegerValue];
	
	if( used < limit ) {
		++ used;
		[pair removeObjectAtIndex: 1];
		[pair addObject: [NSNumber numberWithUnsignedInteger: used]];
		hold = YES;
	} else {
		if( (pool = [_asyncTaskLimiterPoolDict objectForKey: name]) != nil ) {
			if( [anAsyncTask limiterOrder] == HYAsyncTaskActiveOrderToFirst ) {
				[pool insertObject: anAsyncTask atIndex: 0];
			} else {
				[pool addObject: anAsyncTask];
			}
		}
	}
	
	return hold;
}

- (id) throwawayLimiterForName: (NSString *)name
{
	NSMutableArray		*pair;
	NSMutableArray		*pool;
	NSUInteger			used;
	id					anAsyncTask;
	
	if( [name length] <= 0 ) {
		return nil;
	}
	
	if( (pair = [_asyncTaskLimiterDict objectForKey: name]) == nil ) {
		return nil;
	}
	
	anAsyncTask = nil;
	
	if( (used = [[pair objectAtIndex: 1] unsignedIntegerValue]) > 0 ) {
		-- used;
		[pair removeObjectAtIndex: 1];
		[pair addObject: [NSNumber numberWithUnsignedInteger: used]];
		if( (pool = [_asyncTaskLimiterPoolDict objectForKey: name]) != nil ) {
			if( [pool count] > 0 ) {
				anAsyncTask = [pool objectAtIndex: 0];
				[pool removeObjectAtIndex: 0];
			}
		}
	}
	
	return anAsyncTask;
}

- (BOOL) matchingAsyncTask: (id)anAsyncTask withQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName
{
	BOOL			matchQueryIssuedId;
	BOOL			matchWorkerName;
	BOOL			matchExecutorName;
	
	if( queryIssuedId > 0 ) {
		matchQueryIssuedId = ([anAsyncTask madeByQueryIssuedId] == queryIssuedId);
	} else {
		matchQueryIssuedId = YES;
	}
	if( [workerName length] > 0 ) {
		matchWorkerName = [[anAsyncTask madeByWorkerName] isEqualToString: workerName];
	} else {
		matchWorkerName = YES;
	}
	if( [executorName length] > 0 ) {
		matchExecutorName = [[anAsyncTask madeByExecutorName] isEqualToString: executorName];
	} else {
		matchExecutorName = YES;
	}
	
	return ((matchQueryIssuedId == YES) && (matchWorkerName == YES) && (matchExecutorName == YES));
}

- (void) pauseAsyncTaskWithQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	if( (queryIssuedId <= 0) && ([workerName length] <= 0) && ([executorName length] <= 0) ) {
		return;
	}
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
					[anAsyncTask pause];
				}
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
			[anAsyncTask pause];
		}
	}
	
	[_lockForAsyncTaskDict unlock];
}

- (void) resumeAsyncTaskWithQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	if( (queryIssuedId <= 0) && ([workerName length] <= 0) && ([executorName length] <= 0) ) {
		return;
	}
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
					[anAsyncTask resume];
				}
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
			[anAsyncTask resume];
			if( [anAsyncTask running] == NO ) {
				[anAsyncTask performSelectorOnMainThread: @selector(bind) withObject: nil waitUntilDone: NO];
			}
		}
	}
		
	[_lockForAsyncTaskDict unlock];
}

- (void) resumeAllAsyncTaskForMadeByQuery
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([[anAsyncTask madeByWorkerName] length] > 0) || ([[anAsyncTask madeByExecutorName] length] > 0) ) {
					[anAsyncTask resume];
				}
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([[anAsyncTask madeByWorkerName] length] > 0) || ([[anAsyncTask madeByExecutorName] length] > 0) ) {
			[anAsyncTask resume];
			if( [anAsyncTask running] == NO ) {
				[anAsyncTask performSelectorOnMainThread: @selector(bind) withObject: nil waitUntilDone: NO];
			}
		}
	}
		
	[_lockForAsyncTaskDict unlock];
}

- (void) unbindAsyncTaskWithQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i;
	id				anAsyncTask;
	
	if( (queryIssuedId <= 0) && ([workerName length] <= 0) && ([executorName length] <= 0) ) {
		return;
	}
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		i = 0;
		while( [pool count] > 0 ) {
			anAsyncTask = [pool objectAtIndex: i];
			if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
				[anAsyncTask cancel];
				[pool removeObjectAtIndex: i];
				i = 0;
				continue;
			}
			++ i;
			if( i >= [pool count] ) {
				break;
			}
		}
	}
	
	pool = [[NSMutableArray alloc] init];
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
			[pool addObject: key];
			[anAsyncTask cancel];
			if( [anAsyncTask running] == YES ) {
				[anAsyncTask unbind];
			}
		}
	}
	
	for( key in pool ) {
		[_asyncTaskDict removeObjectForKey: key];
	}
		
	[_lockForAsyncTaskDict unlock];
}

- (void) unbindAllAsyncTasksForMadeByQuery
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		i = 0;
		while( [pool count] > 0 ) {
			anAsyncTask = [pool objectAtIndex: i];
			if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([[anAsyncTask madeByWorkerName] length] > 0) || ([[anAsyncTask madeByExecutorName] length] > 0) ) {
				[anAsyncTask cancel];
				[pool removeObjectAtIndex: i];
				i = 0;
				continue;
			}
			++ i;
			if( i >= [pool count] ) {
				break;
			}
		}
	}
	
	pool = [[NSMutableArray alloc] init];
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([[anAsyncTask madeByWorkerName] length] > 0) || ([[anAsyncTask madeByExecutorName] length] > 0) ) {
			[pool addObject: key];
			[anAsyncTask cancel];
			if( [anAsyncTask running] == YES ) {
				[anAsyncTask unbind];
			}
		}
	}
	
	for( key in pool ) {
		[_asyncTaskDict removeObjectForKey: key];
	}
		
	[_lockForAsyncTaskDict unlock];
}

- (BOOL) bindAsyncTask: (id)anAsyncTask
{
	NSString	*limiterName;
	BOOL		bind;
	
	if( (anAsyncTask == nil) || ([anAsyncTask isKindOfClass: [HYAsyncTask class]] == NO) ) {
		return NO;
	}
	
	bind = YES;
	
	[_lockForAsyncTaskDict lock];
	
	if( (limiterName = [anAsyncTask limiterName]) != nil ) {
		[self setLimiterWithCount: [anAsyncTask limiterCount] forName: limiterName];
		if( [self holdLimiterWithaAsyncTask: anAsyncTask forName: limiterName] == NO ) {
			bind = NO;
		}
	}
	
	if( bind == YES ) {
		[_asyncTaskDict setObject: anAsyncTask forKey: [[NSNumber numberWithUnsignedInteger:(NSUInteger)[anAsyncTask issuedId]] stringValue]];
		if( [anAsyncTask paused] == YES ) {
			bind = NO;
		} else {
			[anAsyncTask performSelectorOnMainThread: @selector(bind) withObject: nil waitUntilDone: NO];
		}
	}
	
	[_lockForAsyncTaskDict unlock];
	
	return bind;
}

- (void) unbindAsyncTaskForIssuedId: (int32_t)issuedId
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				if( [anAsyncTask issuedId] == issuedId ) {
					[anAsyncTask cancel];
					[pool removeObjectAtIndex: i];
					[_lockForAsyncTaskDict unlock];
					return;
				}
			}
		}
	}
	
	key = [[NSNumber numberWithUnsignedInteger: (NSUInteger)issuedId] stringValue];
	
	if( (anAsyncTask = [_asyncTaskDict objectForKey: key]) != nil ) {
		limiterName = [anAsyncTask limiterName];
		if( [anAsyncTask running] == YES ) {
			[anAsyncTask unbind];
		}
		[_asyncTaskDict removeObjectForKey: key];
		if( [limiterName length] > 0 ) {
			anAsyncTask = [self throwawayLimiterForName: limiterName];
		} else {
			anAsyncTask = nil;
		}
	}
	
	[_lockForAsyncTaskDict unlock];
	
	if( anAsyncTask != nil ) {
		[self bindAsyncTask: anAsyncTask];
	}
}

- (void) unbindAllAsyncTasks
{
	NSMutableArray	*pair;
	NSMutableArray	*pool;
	NSString		*limiterName;
	NSString		*key;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterDict ) {
		pair = [_asyncTaskLimiterDict objectForKey: limiterName];
		[pair removeObjectAtIndex: 1];
		[pair addObject: [NSNumber numberWithUnsignedInteger: 0]];
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		for( anAsyncTask in pool ) {
			[anAsyncTask cancel];
		}
		[pool removeAllObjects];
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		if( [anAsyncTask running] == YES ) {
			[anAsyncTask unbind];
		}
	}
	[_asyncTaskDict removeAllObjects];
	
	[_lockForAsyncTaskDict unlock];
}

- (void) pauseAsyncTaskForIssuedId: (int32_t)issuedId
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				if( [anAsyncTask issuedId] == issuedId ) {
					[anAsyncTask pause];
					[_lockForAsyncTaskDict unlock];
					return;
				}
			}
		}
	}
	
	key = [[NSNumber numberWithUnsignedInteger: (NSUInteger)issuedId] stringValue];
	
	if( (anAsyncTask = [_asyncTaskDict objectForKey: key]) != nil ) {
		[anAsyncTask pause];
	}
	
	[_lockForAsyncTaskDict unlock];
}

- (void) resumeAsyncTaskForIssuedId: (int32_t)issuedId
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				if( [anAsyncTask issuedId] == issuedId ) {
					[anAsyncTask resume];
					[_lockForAsyncTaskDict unlock];
					return;
				}
			}
		}
	}
	
	key = [[NSNumber numberWithUnsignedInteger: (NSUInteger)issuedId] stringValue];
	
	if( (anAsyncTask = [_asyncTaskDict objectForKey: key]) != nil ) {
		[anAsyncTask resume];
		if( [anAsyncTask running] == NO ) {
			[anAsyncTask performSelectorOnMainThread: @selector(bind) withObject: nil waitUntilDone: NO];
		}
	}
	
	[_lockForAsyncTaskDict unlock];
}

- (void) resumeAllAsyncTasks
{
	NSString		*key;
	NSString		*limiterName;
	NSMutableArray	*pool;
	NSInteger		i, count;
	id				anAsyncTask;
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = [_asyncTaskLimiterPoolDict objectForKey: limiterName];
		if( (count = [pool count]) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = [pool objectAtIndex: i];
				[anAsyncTask resume];
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = [_asyncTaskDict objectForKey: key];
		[anAsyncTask resume];
		if( [anAsyncTask running] == NO ) {
			[anAsyncTask performSelectorOnMainThread: @selector(bind) withObject: nil waitUntilDone: NO];
		}
	}
	
	[_lockForAsyncTaskDict unlock];
}

- (void) postNotificationMigrationStatus: (HydraNotificationCode)status suggestedNumber: (NSUInteger)suggestedNumber referenceNumber: (NSUInteger)referenceNumber thread: (BOOL)thread
{
	NSDictionary		*paramDict;
	
	paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger: (NSInteger)status], HydraNotifiationCodeKey,
												[NSNumber numberWithUnsignedInteger: suggestedNumber], HydraNotificationMigrationSuggestNumber,
												[NSNumber numberWithUnsignedInteger: referenceNumber], HydraNotificationMigrationReferenceNumber,
									nil];
	
	if( thread == YES ) {
		[self performSelectorOnMainThread: @selector(postNotificationWithParamDict:) withObject: paramDict waitUntilDone: YES];
	} else {
		[self postNotificationWithParamDict: paramDict];
	}
}

- (void) postNotificationWithParamDict: (NSDictionary *)paramDict
{
	[[NSNotificationCenter defaultCenter] postNotificationName: HydraNotification object: self userInfo: paramDict];
}

- (void) stepMigration: (id)migration
{
	NSUInteger			lastUpdated;
	NSUInteger			suggested;
	NSUInteger			step;
	
    @autoreleasepool {
	
        suggested = [migration suggestedMigrationNumber];
        lastUpdated = [migration lastUpdatedMigrationNumber];
        
        if( lastUpdated == 0 ) {
            [self postNotificationMigrationStatus: HydraNotificationCodeMigrationWillInitialing suggestedNumber: suggested referenceNumber: lastUpdated thread: [migration useBackgroundThread]];
            if( [migration doInitialing] == YES ) {
                lastUpdated = 1;
                [migration initialingDone];
                [self postNotificationMigrationStatus: HydraNotificationCodeMigrationDidInitialing suggestedNumber: suggested referenceNumber: lastUpdated thread: [migration useBackgroundThread]];
            } else {
                [self postNotificationMigrationStatus: HydraNotificationCodeMigrationFailedAtInitialing suggestedNumber: suggested referenceNumber: lastUpdated thread: [migration useBackgroundThread]];
            }
        }
        
        if( lastUpdated > 0 ) {
            if( lastUpdated >= suggested ) {
                [self postNotificationMigrationStatus: HydraNotificationCodeMigrationNothingToDo suggestedNumber: suggested referenceNumber: lastUpdated thread: [migration useBackgroundThread]];
            } else {
                [self postNotificationMigrationStatus: HydraNotificationCodeMigrationWillStart suggestedNumber: suggested referenceNumber: lastUpdated thread: [migration useBackgroundThread]];
                step = lastUpdated + 1;
                while( 1 ) {
                    if( [migration isSomethingToDoForMigrationNumber: step] == YES ) {
                        [self postNotificationMigrationStatus: HydraNotificationCodeMigrationWillStep suggestedNumber: suggested referenceNumber: step thread: [migration useBackgroundThread]];
                        if( [migration stepMigrationForNumber: step] == NO ) {
                            [self postNotificationMigrationStatus: HydraNotificationCodeMigrationFailedAtStep suggestedNumber: suggested referenceNumber: step thread: [migration useBackgroundThread]];
                            -- step;
                            break;
                        }
                        [self postNotificationMigrationStatus: HydraNotificationCodeMigrationDidStep suggestedNumber: suggested referenceNumber: step thread: [migration useBackgroundThread]];
                        
                    }
                    if( ++step > suggested ) {
                        break;
                    }
                }
                if( step > suggested ) {
                    [self postNotificationMigrationStatus: HydraNotificationCodeMigrationDone suggestedNumber: suggested referenceNumber: [migration lastUpdatedMigrationNumber] thread: [migration useBackgroundThread]];
                }
            }
        }
        
    }
}

- (void) updateTrackingResultSetAndNotifyIfNeed: (id)anResult
{
	NSString				*name;
	HYTrackingResultSet		*resultSet;
	NSDictionary			*resultDict;
	NSMutableDictionary		*postNotifyDict;
	
	postNotifyDict = nil;
	
	[_lockForTrackingResultSets lock];
	
	if( [_trackingResultSets count] > 0 ) {
		for( name in _trackingResultSets ) {
			resultSet = [_trackingResultSets objectForKey: name];
			if( [resultSet updateResult: anResult] == YES ) {
				if( (resultDict = [resultSet resultDict]) != nil ) {
					if( postNotifyDict == nil ) {
						postNotifyDict = [[NSMutableDictionary alloc] init];
					}
					[postNotifyDict setObject: [NSDictionary dictionaryWithDictionary: resultDict] forKey: [resultSet name]];
					[resultSet touch];
				}
			}
		}
	}
	
	[_lockForTrackingResultSets unlock];
	
	if( [postNotifyDict count] > 0 ) {
		for( name in postNotifyDict ) {
			resultDict = [postNotifyDict objectForKey: name];
			[[NSNotificationCenter defaultCenter] postNotificationName: name object: self userInfo: resultDict];
		}
	}
}

- (BOOL) setWaitingResultWithQuery: (id)anQuery
{
	NSMutableDictionary		*issuedIdDict;
	NSNumber				*issuedId;
	BOOL					alreadyWaiting;
		
	[_lockForWaitingResults lock];
	
	if( (issuedIdDict = [_waitingResults objectForKey: [anQuery waitingResultName]]) == nil ) {
		alreadyWaiting = NO;
		if( (issuedIdDict = [[NSMutableDictionary alloc] init]) != nil ) {
			[_waitingResults setObject: issuedIdDict forKey: [anQuery waitingResultName]];
		}
	} else {
		alreadyWaiting = YES;
	}
	issuedId = [NSNumber numberWithLong: [anQuery issuedId]];
	[issuedIdDict setObject: anQuery forKey: [issuedId stringValue]];
	
	[_lockForWaitingResults unlock];
		
	if( ([anQuery skipMeIfAlreadyWaiting] == YES) && (alreadyWaiting == YES) ) {
		return NO;
	}
	
	[NSTimer scheduledTimerWithTimeInterval: [anQuery waitingTimeoutInterval]
									 target: self
								   selector: @selector(timerForWaitingResultTimeout:)
								   userInfo: [NSDictionary dictionaryWithObject: issuedId forKey: [anQuery waitingResultName]]
									repeats: NO];
	
	return YES;
}

- (void) timerForWaitingResultTimeout: (NSTimer *)anTimer
{
	NSDictionary			*userInfo;
	NSString				*resultName;
	NSMutableDictionary		*issuedIdDict;
	NSNumber				*expiredIssuedId;
	id						expiredQuery;
	id						anWorker;
	BOOL					notifyFlag;
	
	if( (userInfo = [anTimer userInfo]) == nil ) {
		return;
	}
	if( [userInfo count] != 1 ) {
		return;
	}
	
	notifyFlag = NO;
	expiredQuery = nil;
	
	[_lockForWaitingResults lock];
	
	for( resultName in userInfo ) {
		expiredIssuedId = [userInfo objectForKey: resultName];
		if( (issuedIdDict = [_waitingResults objectForKey: resultName]) != nil ) {
			if( (expiredQuery = [issuedIdDict objectForKey: [expiredIssuedId stringValue]]) != nil ) {
				if( [expiredQuery canceled] == NO ) {
					notifyFlag = YES;
				}
				[issuedIdDict removeObjectForKey: [expiredIssuedId stringValue]];
				break;
			}
		}
	}
	
	[_lockForWaitingResults unlock];
	
	if( (notifyFlag == YES) && (expiredQuery != nil) ) {
		if( (anWorker = [_workerDict objectForKey: [expiredQuery workerName]]) != nil ) {
			[anWorker expireQuery: expiredQuery];
		}
	}
}

- (void) clearResultAtWaitings: (id)anResult
{
	[_lockForWaitingResults lock];
	
	[_waitingResults removeObjectForKey: [anResult name]];
	
	[_lockForWaitingResults unlock];
}

- (void) workerStarted: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = [params objectForKey: HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger: (NSInteger)HydraNotificationCodeDidStartWorker], HydraNotifiationCodeKey,
											  [anWorker name], HydraNotificationWorkerNameKey,
											  nil]];
	}
}

- (void) workerPaused: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = [params objectForKey: HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger: (NSInteger)HydraNotificationCodeDidPauseWorker], HydraNotifiationCodeKey,
											  [anWorker name], HydraNotificationWorkerNameKey,
											  nil]];
	}
}

- (void) workerResumed: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = [params objectForKey: HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger: (NSInteger)HydraNotificationCodeDidResumeWorker], HydraNotifiationCodeKey,
											  [anWorker name], HydraNotificationWorkerNameKey,
											  nil]];
	}
}

- (void) workerStopped: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = [params objectForKey: HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger: (NSInteger)HydraNotificationCodeDidStopWorker], HydraNotifiationCodeKey,
											  [anWorker name], HydraNotificationWorkerNameKey,
											  nil]];
	}
}

- (void) workerPostNotifyResult: (NSDictionary *)params
{
	id				anWorker;
	NSDictionary	*resultDict;
	NSString		*name;
	id				anResult;
	
	if( (anWorker = [params objectForKey: HYWorkerParameterKeyWorker]) == nil ) {
		return;
	}
	if( (resultDict = [params objectForKey: HYWorkerParameterKeyResultDict]) == nil ) {
		return;
	}
	
	for( name in resultDict ) {
		anResult = [resultDict objectForKey: name];
		if( [anResult isKindOfClass: [HYResult class]] == NO ) {
			continue;
		}
		[self clearResultAtWaitings: anResult];
		[[NSNotificationCenter defaultCenter] postNotificationName: [anWorker name]
															object: self
														  userInfo: [NSDictionary dictionaryWithObjectsAndKeys: anResult, [anResult name], nil]];
		[self updateTrackingResultSetAndNotifyIfNeed: anResult];
	}
}

- (NSString *) description
{
	NSString			*desc;
	NSString			*name;
	HYWorker			*worker;
	HYTrackingResultSet	*trackingResultSet;
	NSString			*key;
	id					anObject;
	HYAsyncTask			*asyncTack;
	NSMutableArray		*pair;
	
	desc = [NSString stringWithFormat: @"<hydra name=\"%@\">", _name];
	desc = [desc stringByAppendingFormat: @"<workers>"];
	for( name in _workerDict ) {
		worker = [_workerDict objectForKey: name];
		desc = [desc stringByAppendingFormat: @"%@", worker];
	}
	desc = [desc stringByAppendingString: @"</workers>"];
	desc = [desc stringByAppendingFormat: @"<tracking_resultsets>"];
	[_lockForTrackingResultSets lock];
	for( name in _trackingResultSets ) {
		trackingResultSet = [_trackingResultSets objectForKey: name];
		desc = [desc stringByAppendingFormat: @"%@", trackingResultSet];
	}
	[_lockForTrackingResultSets unlock];
	desc = [desc stringByAppendingString: @"</tracking_resultsets>"];
	desc = [desc stringByAppendingFormat: @"<shared_data>"];
	[_lockForSharedDataDict lock];
	for( key in _sharedDataDict ) {
		anObject = [_sharedDataDict objectForKey: key];
		if( [anObject respondsToSelector: @selector(description)] == YES ) {
			desc = [desc stringByAppendingFormat: @"<key name=\"%@\">", key];
			desc = [desc stringByAppendingFormat: @"%@", anObject];
			desc = [desc stringByAppendingFormat: @"</key>"];
		} else {
			desc = [desc stringByAppendingFormat: @"<key name=\"%@\"/>", key];
		}
	}
	[_lockForSharedDataDict unlock];
	desc = [desc stringByAppendingString: @"</shared_data>"];
	
	desc = [desc stringByAppendingString: @"<asynctask_limiters>"];
	[_lockForAsyncTaskDict lock];
	for( key in _asyncTaskDict ) {
		pair = [_asyncTaskLimiterDict objectForKey: key];
		desc = [desc stringByAppendingFormat: @"<asynctask_limiter name=\"%@\" limit=\"%@\" used=\"%@\"", key, [pair objectAtIndex: 0], [pair objectAtIndex: 1]];
	}
	[_lockForAsyncTaskDict unlock];
	desc = [desc stringByAppendingString: @"</asynctask_limiters>"];
	
	desc = [desc stringByAppendingString: @"<asynctasks>"];
	[_lockForAsyncTaskDict lock];
	for( key in _asyncTaskDict ) {
		asyncTack = [_asyncTaskDict objectForKey: key];
		desc = [desc stringByAppendingFormat: @"%@", asyncTack];
	}
	[_lockForAsyncTaskDict unlock];
	desc = [desc stringByAppendingString: @"</asynctasks>"];
	desc = [desc stringByAppendingString: @"</hydra>"];
	
	return desc;
}

@end
