//
//  Hydra.m
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "Hydra.h"


@interface Hydra ()
{
    NSMutableDictionary		*_workerDict;
    NSMutableDictionary		*_sharedDataDict;
    NSLock					*_lockForSharedDataDict;
    NSMutableDictionary		*_trackingResultSets;
    NSLock					*_lockForTrackingResultSets;
    NSMutableDictionary		*_waitingResults;
    NSLock					*_lockForWaitingResults;
    NSMutableDictionary		*_asyncTaskDict;
    NSMutableDictionary		*_asyncTaskLimiterDict;
    NSMutableDictionary		*_asyncTaskLimiterPoolDict;
    NSLock					*_lockForAsyncTaskDict;
}

- (instancetype) initWithName: (NSString *)name;
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

+ (Hydra *) defaultHydra
{
    static dispatch_once_t once;
    static Hydra *sharedInstance;
    dispatch_once(&once, ^{sharedInstance = [[self alloc] initWithName:kHydraDefaultName];});
    return sharedInstance;
}

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
	
	if( _workerDict[[anWorker name]] != nil ) {
		return NO;
	}
	
	((HYWorker *)anWorker).delegate = self;
	_workerDict[[anWorker name]] = anWorker;
	
	return YES;
}

- (void) removeWorkerForName: (NSString *)name
{
	if( name.length <= 0 ) {
		return;
	}
		
	[_workerDict removeObjectForKey: name];
}

- (id) workerForName: (NSString *)name
{
	if( name.length <= 0 ) {
		return nil;
	}
	
	return _workerDict[name];
}

- (void) startAllWorkers
{
	NSString		*name;
	id				anWorker;
	
	for( name in _workerDict ) {
		anWorker = _workerDict[name];
		if( [anWorker isRunning] == NO ) {
			[anWorker startWorker];
		}
	}
}

- (void) startWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( name.length <= 0 ) {
		return;
	}
	
	if( (anWorker = _workerDict[name]) != nil ) {
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
		anWorker = _workerDict[name];
		if( [anWorker isRunning] == YES ) {
			[anWorker pauseWorker];
		}
	}
}

- (void) pauseWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( name.length <= 0 ) {
		return;
	}
	
	if( (anWorker = _workerDict[name]) != nil ) {
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
		anWorker = _workerDict[name];
		if( [anWorker isPaused] == YES ) {
			[anWorker resumeWorker];
		}
	}
}

- (void) resumeWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( name.length <= 0 ) {
		return;
	}
	
	if( (anWorker = _workerDict[name]) != nil ) {
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
		anWorker = _workerDict[name];
		if( [anWorker isStarted] == YES ) {
			[anWorker stopWorker];
		}
	}
}

- (void) stopWorkerForName: (NSString *)name
{
	id				anWorker;
	
	if( name.length <= 0 ) {
		return;
	}
	
	if( (anWorker = _workerDict[name]) != nil ) {
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
	
	if( (worker = _workerDict[[anQuery workerName]]) == nil ) {
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
		[_workerDict[workerName] pauseQueryForIssuedId: issuedId];
	}
	
	[self pauseAsyncTaskWithQueryIssuedId: issuedId workerName: nil executorName: nil];
}

- (void) pauseAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName
{
	if( (executorName.length <= 0) || (workerName.length <= 0) ) {
		return;
	}
	
	[_workerDict[workerName] pauseAllQueriesForExecutorName: executorName];
	
	[self pauseAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: executorName];
}

- (void) resumeQueryForIssuedId: (int32_t)issuedId
{
	NSString		*workerName;
	
	for( workerName in _workerDict ) {
		[_workerDict[workerName] resumeQueryForIssuedId: issuedId];
	}
	
	[self resumeAsyncTaskWithQueryIssuedId: issuedId workerName: nil executorName: nil];
}

- (void) resumeAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName
{
	if( (executorName.length <= 0) || (workerName.length <= 0) ) {
		return;
	}
	
	[_workerDict[workerName] resumeAllQueriesForExecutorName: executorName];
	
	[self resumeAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: executorName];
}

- (void) resumeAllQueries
{
	NSString	*workerName;
	id			anWorker;
	
	for( workerName in _workerDict ) {
		anWorker = _workerDict[workerName];
		[anWorker resumeAllQueries];
	}
	
	[self resumeAllAsyncTaskForMadeByQuery];
}

- (void) cancelQueryForIssuedId: (int32_t)issuedId
{
	NSString		*workerName;
	
	for( workerName in _workerDict ) {
		[_workerDict[workerName] cancelQueryForIssuedId: issuedId];
	}
	
	[self unbindAsyncTaskWithQueryIssuedId: issuedId workerName: nil executorName: nil];
}

- (void) cancelAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName
{
	if( (executorName.length <= 0) || (workerName.length <= 0) ) {
		return;
	}
	
	[_workerDict[workerName] cancelAllQueriesForExecutorName: executorName];
	
	[self unbindAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: executorName];
}

- (void) cancelAllQueriesForWorkerName: (NSString *)workerName
{
	if( workerName.length <= 0 ) {
		return;
	}
	
	[_workerDict[workerName] cancelAllQueries];
	
	[self unbindAsyncTaskWithQueryIssuedId: 0 workerName: workerName executorName: nil];
}

- (void) cancelAllQueries
{
	NSString	*workerName;
	id			anWorker;
	
	for( workerName in _workerDict ) {
		anWorker = _workerDict[workerName];
		[anWorker cancelAllQueries];
	}
	
	[self unbindAllAsyncTasksForMadeByQuery];
}

- (BOOL) setTrackingResultSet: (id)anTrackingResultSet
{
	if( [anTrackingResultSet isKindOfClass: [HYTrackingResultSet class]] == NO ) {
		return NO;
	}
	
	if( _trackingResultSets[[anTrackingResultSet name]] != nil ) {
		return NO;
	}
	
	[_lockForTrackingResultSets lock];
	
	_trackingResultSets[[anTrackingResultSet name]] = anTrackingResultSet;
	
	[_lockForTrackingResultSets unlock];
	
	return YES;
}

- (void) removeTrackingResultSetForName: (NSString *)name
{
	if( name.length <= 0 ) {
		return;
	}
	
	[_lockForTrackingResultSets lock];
	
	[_trackingResultSets removeObjectForKey: name];
	
	[_lockForTrackingResultSets unlock];
}

- (id) cacheDataAtWorker: (NSString *)name forKey: (NSString *)key
{
	id		anWorker;
	
	if( (name.length <= 0) || (key.length <= 0) ) {
		return nil;
	}
	
	if( (anWorker = _workerDict[name]) == nil ) {
		return nil;
	}
	
	return [anWorker cacheDataForKey: key];
}

- (BOOL) setCacheData: (id)anData atWoker: (NSString *)name forKey: (NSString *)key
{
	id		anWorker;
	
	if( (name.length <= 0) || (key.length <= 0) ) {
		return NO;
	}
	
	if( (anWorker = _workerDict[name]) == nil ) {
		return NO;
	}
	
	return [anWorker setCacheData: anData forKey: key];
}

- (void) removeCacheDataAtWorker: (NSString *)name forKey: (NSString *)key
{
	id		anWorker;
	
	if( (name.length <= 0) || (key.length <= 0) ) {
		return;
	}
	
	if( (anWorker = _workerDict[name]) == nil ) {
		return;
	}
	
	[anWorker removeCacheDataForKey: key];
}

- (void) removeAllCacheDataAtWorker: (NSString *)name
{
	id		anWorker;
	
	if( name.length <= 0 ) {
		return;
	}
	
	if( (anWorker = _workerDict[name]) == nil ) {
		return;
	}
	
	[anWorker removeAllCacheData];
}

- (id) sharedDataForKey: (NSString *)key
{
	id		anData;
	
	if( key.length <= 0 ) {
		return nil;
	}
	
	[_lockForSharedDataDict lock];
	
	anData = _sharedDataDict[key];
	
	[_lockForSharedDataDict unlock];
	
	return anData;
}

- (BOOL) setSharedData: (id)anData forKey: (NSString *)key
{
	if( (anData == nil) || (key.length <= 0) ) {
		return NO;
	}
	
	[_lockForSharedDataDict lock];
	
	_sharedDataDict[key] = anData;
	
	[_lockForSharedDataDict unlock];
	
	return YES;
}

- (void) removeSharedDataForKey: (NSString *)key
{
	if( key.length <= 0 ) {
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
	
	if( (count <= 0) || name.length <= 0 ) {
		return NO;
	}
	
	set = NO;
		
	if( (pair = _asyncTaskLimiterDict[name]) != nil ) {
		if( [pair[0] unsignedIntegerValue] != count ) {
			[pair removeObjectAtIndex: 0];
			[pair insertObject: @(count) atIndex: 0];
		}
		set = YES;
	} else {
		if( (pair = [[NSMutableArray alloc] init]) != nil ) {
			if( (pool = [[NSMutableArray alloc] init]) != nil ) {
				[pair addObject: @(count)];
				[pair addObject: @(0)];
				_asyncTaskLimiterDict[name] = pair;
				_asyncTaskLimiterPoolDict[name] = pool;
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
	
	if( name.length <= 0 ) {
		return NO;
	}
	
	if( (pair = _asyncTaskLimiterDict[name]) == nil ) {
		return NO;
	}
	
	hold = NO;
	limit = [pair[0] unsignedIntegerValue];
	used = [pair[1] unsignedIntegerValue];
	
	if( used < limit ) {
		++ used;
		[pair removeObjectAtIndex: 1];
		[pair addObject: @(used)];
		hold = YES;
	} else {
		if( (pool = _asyncTaskLimiterPoolDict[name]) != nil ) {
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
	
	if( name.length <= 0 ) {
		return nil;
	}
	
	if( (pair = _asyncTaskLimiterDict[name]) == nil ) {
		return nil;
	}
	
	anAsyncTask = nil;
	
	if( (used = [pair[1] unsignedIntegerValue]) > 0 ) {
		-- used;
		[pair removeObjectAtIndex: 1];
		[pair addObject: @(used)];
		if( (pool = _asyncTaskLimiterPoolDict[name]) != nil ) {
			if( pool.count > 0 ) {
				anAsyncTask = pool[0];
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
	if( workerName.length > 0 ) {
		matchWorkerName = [[anAsyncTask madeByWorkerName] isEqualToString: workerName];
	} else {
		matchWorkerName = YES;
	}
	if( executorName.length > 0 ) {
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
	
	if( (queryIssuedId <= 0) && (workerName.length <= 0) && (executorName.length <= 0) ) {
		return;
	}
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
					[anAsyncTask pause];
				}
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
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
	
	if( (queryIssuedId <= 0) && (workerName.length <= 0) && (executorName.length <= 0) ) {
		return;
	}
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
					[anAsyncTask resume];
				}
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
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
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([anAsyncTask madeByWorkerName].length > 0) || ([anAsyncTask madeByExecutorName].length > 0) ) {
					[anAsyncTask resume];
				}
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
		if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([anAsyncTask madeByWorkerName].length > 0) || ([anAsyncTask madeByExecutorName].length > 0) ) {
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
	
	if( (queryIssuedId <= 0) && (workerName.length <= 0) && (executorName.length <= 0) ) {
		return;
	}
	
	[_lockForAsyncTaskDict lock];
	
	for( limiterName in _asyncTaskLimiterPoolDict ) {
		pool = _asyncTaskLimiterPoolDict[limiterName];
		i = 0;
		while( pool.count > 0 ) {
			anAsyncTask = pool[i];
			if( [self matchingAsyncTask: anAsyncTask withQueryIssuedId: queryIssuedId workerName: workerName executorName: executorName] == YES ) {
				[anAsyncTask cancel];
				[pool removeObjectAtIndex: i];
				i = 0;
				continue;
			}
			++ i;
			if( i >= pool.count ) {
				break;
			}
		}
	}
	
	pool = [[NSMutableArray alloc] init];
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
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
		pool = _asyncTaskLimiterPoolDict[limiterName];
		i = 0;
		while( pool.count > 0 ) {
			anAsyncTask = pool[i];
			if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([anAsyncTask madeByWorkerName].length > 0) || ([anAsyncTask madeByExecutorName].length > 0) ) {
				[anAsyncTask cancel];
				[pool removeObjectAtIndex: i];
				i = 0;
				continue;
			}
			++ i;
			if( i >= pool.count ) {
				break;
			}
		}
	}
	
	pool = [[NSMutableArray alloc] init];
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
		if( ([anAsyncTask madeByQueryIssuedId] > 0) || ([anAsyncTask madeByWorkerName].length > 0) || ([anAsyncTask madeByExecutorName].length > 0) ) {
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
		_asyncTaskDict[@((NSUInteger)[anAsyncTask issuedId]).stringValue] = anAsyncTask;
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
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				if( [anAsyncTask issuedId] == issuedId ) {
					[anAsyncTask cancel];
					[pool removeObjectAtIndex: i];
					[_lockForAsyncTaskDict unlock];
					return;
				}
			}
		}
	}
	
	key = @((NSUInteger)issuedId).stringValue;
	
	if( (anAsyncTask = _asyncTaskDict[key]) != nil ) {
		limiterName = [anAsyncTask limiterName];
		if( [anAsyncTask running] == YES ) {
			[anAsyncTask unbind];
		}
		[_asyncTaskDict removeObjectForKey: key];
		if( limiterName.length > 0 ) {
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
		pair = _asyncTaskLimiterDict[limiterName];
		[pair removeObjectAtIndex: 1];
		[pair addObject: @0U];
		pool = _asyncTaskLimiterPoolDict[limiterName];
		for( anAsyncTask in pool ) {
			[anAsyncTask cancel];
		}
		[pool removeAllObjects];
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
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
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				if( [anAsyncTask issuedId] == issuedId ) {
					[anAsyncTask pause];
					[_lockForAsyncTaskDict unlock];
					return;
				}
			}
		}
	}
	
	key = @((NSUInteger)issuedId).stringValue;
	
	if( (anAsyncTask = _asyncTaskDict[key]) != nil ) {
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
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				if( [anAsyncTask issuedId] == issuedId ) {
					[anAsyncTask resume];
					[_lockForAsyncTaskDict unlock];
					return;
				}
			}
		}
	}
	
	key = @((NSUInteger)issuedId).stringValue;
	
	if( (anAsyncTask = _asyncTaskDict[key]) != nil ) {
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
		pool = _asyncTaskLimiterPoolDict[limiterName];
		if( (count = pool.count) > 0 ) {
			for( i=0 ; i<count ; ++i ) {
				anAsyncTask = pool[i];
				[anAsyncTask resume];
			}
		}
	}
	
	for( key in _asyncTaskDict ) {
		anAsyncTask = _asyncTaskDict[key];
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
	
	paramDict = @{HydraNotifiationCodeKey: @((NSInteger)status),
												HydraNotificationMigrationSuggestNumber: @(suggestedNumber),
												HydraNotificationMigrationReferenceNumber: @(referenceNumber)};
	
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
	
        Class migrationClass = [migration class];
        suggested = [[migrationClass performSelector:@selector(suggestedMigrationNumber)] unsignedIntegerValue];
        lastUpdated = [[migrationClass performSelector:@selector(lastUpdatedMigrationNumber)] unsignedIntegerValue];
        
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
                [self postNotificationMigrationStatus: HydraNotificationCodeMigrationDidStart suggestedNumber: suggested referenceNumber: lastUpdated thread: [migration useBackgroundThread]];
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
                    [self postNotificationMigrationStatus: HydraNotificationCodeMigrationDone suggestedNumber: suggested referenceNumber: [migrationClass lastUpdatedMigrationNumber].unsignedIntegerValue thread: [migration useBackgroundThread]];
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
	
	if( _trackingResultSets.count > 0 ) {
		for( name in _trackingResultSets ) {
			resultSet = _trackingResultSets[name];
			if( [resultSet updateResult: anResult] == YES ) {
				if( (resultDict = resultSet.resultDict) != nil ) {
					if( postNotifyDict == nil ) {
						postNotifyDict = [[NSMutableDictionary alloc] init];
					}
					postNotifyDict[resultSet.name] = [NSDictionary dictionaryWithDictionary: resultDict];
					[resultSet touch];
				}
			}
		}
	}
	
	[_lockForTrackingResultSets unlock];
	
	if( postNotifyDict.count > 0 ) {
		for( name in postNotifyDict ) {
			resultDict = postNotifyDict[name];
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
	
	if( (issuedIdDict = _waitingResults[[anQuery waitingResultName]]) == nil ) {
		alreadyWaiting = NO;
		if( (issuedIdDict = [[NSMutableDictionary alloc] init]) != nil ) {
			_waitingResults[[anQuery waitingResultName]] = issuedIdDict;
		}
	} else {
		alreadyWaiting = YES;
	}
	issuedId = @([anQuery issuedId]);
	issuedIdDict[issuedId.stringValue] = anQuery;
	
	[_lockForWaitingResults unlock];
		
	if( ([anQuery skipMeIfAlreadyWaiting] == YES) && (alreadyWaiting == YES) ) {
		return NO;
	}
	
	[NSTimer scheduledTimerWithTimeInterval: [anQuery waitingTimeoutInterval]
									 target: self
								   selector: @selector(timerForWaitingResultTimeout:)
								   userInfo: @{[anQuery waitingResultName]: issuedId}
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
	
	if( (userInfo = anTimer.userInfo) == nil ) {
		return;
	}
	if( userInfo.count != 1 ) {
		return;
	}
	
	notifyFlag = NO;
	expiredQuery = nil;
	
	[_lockForWaitingResults lock];
	
	for( resultName in userInfo ) {
		expiredIssuedId = userInfo[resultName];
		if( (issuedIdDict = _waitingResults[resultName]) != nil ) {
			if( (expiredQuery = issuedIdDict[expiredIssuedId.stringValue]) != nil ) {
				if( [expiredQuery canceled] == NO ) {
					notifyFlag = YES;
				}
				[issuedIdDict removeObjectForKey: expiredIssuedId.stringValue];
				break;
			}
		}
	}
	
	[_lockForWaitingResults unlock];
	
	if( (notifyFlag == YES) && (expiredQuery != nil) ) {
		if( (anWorker = _workerDict[[expiredQuery workerName]]) != nil ) {
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
	
	if( (anWorker = params[HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: @{HydraNotifiationCodeKey: @((NSInteger)HydraNotificationCodeDidStartWorker),
											  HydraNotificationWorkerNameKey: [anWorker name]}];
	}
}

- (void) workerPaused: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = params[HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: @{HydraNotifiationCodeKey: @((NSInteger)HydraNotificationCodeDidPauseWorker),
											  HydraNotificationWorkerNameKey: [anWorker name]}];
	}
}

- (void) workerResumed: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = params[HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: @{HydraNotifiationCodeKey: @((NSInteger)HydraNotificationCodeDidResumeWorker),
											  HydraNotificationWorkerNameKey: [anWorker name]}];
	}
}

- (void) workerStopped: (NSDictionary *)params
{
	id		anWorker;
	
	if( (anWorker = params[HYWorkerParameterKeyWorker]) != nil ) {
		[self postNotificationWithParamDict: @{HydraNotifiationCodeKey: @((NSInteger)HydraNotificationCodeDidStopWorker),
											  HydraNotificationWorkerNameKey: [anWorker name]}];
	}
}

- (void) workerPostNotifyResult: (NSDictionary *)params
{
	id				anWorker;
	NSDictionary	*resultDict;
	NSString		*name;
	id				anResult;
	
	if( (anWorker = params[HYWorkerParameterKeyWorker]) == nil ) {
		return;
	}
	if( (resultDict = params[HYWorkerParameterKeyResultDict]) == nil ) {
		return;
	}
	
	for( name in resultDict ) {
		anResult = resultDict[name];
		if( [anResult isKindOfClass: [HYResult class]] == NO ) {
			continue;
		}
		[self clearResultAtWaitings: anResult];
		[[NSNotificationCenter defaultCenter] postNotificationName: [anWorker name]
															object: self
														  userInfo: @{[anResult name]: anResult}];
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
		worker = _workerDict[name];
		desc = [desc stringByAppendingFormat: @"%@", worker];
	}
	desc = [desc stringByAppendingString: @"</workers>"];
	desc = [desc stringByAppendingFormat: @"<tracking_resultsets>"];
	[_lockForTrackingResultSets lock];
	for( name in _trackingResultSets ) {
		trackingResultSet = _trackingResultSets[name];
		desc = [desc stringByAppendingFormat: @"%@", trackingResultSet];
	}
	[_lockForTrackingResultSets unlock];
	desc = [desc stringByAppendingString: @"</tracking_resultsets>"];
	desc = [desc stringByAppendingFormat: @"<shared_data>"];
	[_lockForSharedDataDict lock];
	for( key in _sharedDataDict ) {
		anObject = _sharedDataDict[key];
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
		pair = _asyncTaskLimiterDict[key];
		desc = [desc stringByAppendingFormat: @"<asynctask_limiter name=\"%@\" limit=\"%@\" used=\"%@\"", key, pair[0], pair[1]];
	}
	[_lockForAsyncTaskDict unlock];
	desc = [desc stringByAppendingString: @"</asynctask_limiters>"];
	
	desc = [desc stringByAppendingString: @"<asynctasks>"];
	[_lockForAsyncTaskDict lock];
	for( key in _asyncTaskDict ) {
		asyncTack = _asyncTaskDict[key];
		desc = [desc stringByAppendingFormat: @"%@", asyncTack];
	}
	[_lockForAsyncTaskDict unlock];
	desc = [desc stringByAppendingString: @"</asynctasks>"];
	desc = [desc stringByAppendingString: @"</hydra>"];
	
	return desc;
}

@end
