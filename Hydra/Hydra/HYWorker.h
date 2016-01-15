//
//  HYWorker.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


#define     HydraCommonWorkerName                   @"hydraCommonWorkerNameLernaean"


@protocol HYWorkerDelegate

@optional
- (void) workerStarted: (NSDictionary *)params;
- (void) workerPaused: (NSDictionary *)params;
- (void) workerResumed: (NSDictionary *)params;
- (void) workerStopped: (NSDictionary *)params;
- (void) workerPostNotifyResult: (NSDictionary *)params;

@end


// parameter key for delegate call operation.

#define		HYWorkerParameterKeyWorker				@"HYWorkerParameterKeyWorker"
#define		HYWorkerParameterKeyResultDict			@"HYWorkerParameterKeyResultDict"


@interface HYWorker : NSObject
{
	__weak id				_delegate;
    NSString                *_name;
	NSMutableDictionary		*_executerDict;
	NSMutableArray			*_queryQueue;
	id						_executingQuery;
	NSCondition				*_condition;
	int						_currentState;
	int						_nextState;
	NSLock					*_lockForCacheDict;
	NSMutableDictionary		*_cacheDict;
}

- (id)initWithCommonWorker;

// you must override and implement these methods.

- (NSString *) name;

// public methods.

- (BOOL) addExecuter: (id)anExecuter;
- (void) removeExecuterForName: (NSString *)name;

// override these methods if need.

- (NSString *) brief;
- (NSString *) customDataDescription;

- (BOOL) didInit;
- (void) willDealloc;
- (BOOL) willStart;
- (void) didStart;
- (BOOL) willPause;
- (void) didPause;
- (BOOL) willResume;
- (void) didResume;
- (BOOL) willStop;
- (void) didStop;
- (BOOL) didFetchQuery: (id)anQuery;
- (BOOL) didCancelQuery: (id)anQuery;
- (BOOL) didExpireQuery: (id)anQuery;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (BOOL) startWorker;
- (BOOL) pauseWorker;
- (BOOL) resumeWorker;
- (BOOL) stopWorker;

- (BOOL) pushQuery: (id)anQuery;
- (BOOL) pushQueryToFront: (id)anQuery;

- (void) pauseQueryForIssuedId: (int32_t)issuedId;
- (void) pauseAllQueriesForExecutorName: (NSString *)executorName;
- (void) resumeQueryForIssuedId: (int32_t)issuedId;
- (void) resumeAllQueriesForExecutorName: (NSString *)executorName;
- (void) resumeAllQueries;

- (void) cancelQueryForIssuedId: (int32_t)issuedId;
- (void) cancelAllQueriesForExecutorName: (NSString *)executorName;
- (void) cancelAllQueries;
- (void) expireQuery: (id)anQuery;

- (BOOL) isStarted;
- (BOOL) isRunning;
- (BOOL) isPaused;

- (id) cacheDataForKey: (NSString *)key;
- (BOOL) setCacheData: (id)anData forKey: (NSString *)key;
- (void) removeCacheDataForKey: (NSString *)key;
- (void) removeAllCacheData;

@property (nonatomic, weak) id delegate;

@end
