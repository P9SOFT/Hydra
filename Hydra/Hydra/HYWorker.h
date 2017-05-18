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
- (void) workerStarted: (NSDictionary * _Nullable)params;
- (void) workerPaused: (NSDictionary * _Nullable)params;
- (void) workerResumed: (NSDictionary * _Nullable)params;
- (void) workerStopped: (NSDictionary * _Nullable)params;
- (void) workerPostNotifyResult: (NSDictionary * _Nullable)params;

@end


// parameter key for delegate call operation.

#define		HYWorkerParameterKeyWorker				@"HYWorkerParameterKeyWorker"
#define		HYWorkerParameterKeyResultDict			@"HYWorkerParameterKeyResultDict"


@interface HYWorker : NSObject

// you must override and implement these methods.

- (NSString * _Nullable) name;

// public methods.

- (BOOL) addExecuter: (id _Nullable)anExecuter;
- (void) removeExecuterForName: (NSString * _Nullable)name;

// override these methods if need.

- (NSString * _Nullable) brief;
- (NSString * _Nullable) customDataDescription;

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
- (BOOL) didFetchQuery: (id _Nullable)anQuery;
- (BOOL) didCancelQuery: (id _Nullable)anQuery;
- (BOOL) didExpireQuery: (id _Nullable)anQuery;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (instancetype _Nullable) initWithName: (NSString * _Nullable)name;

- (BOOL) startWorker;
- (BOOL) pauseWorker;
- (BOOL) resumeWorker;
- (BOOL) stopWorker;

- (BOOL) pushQuery: (id _Nullable)anQuery;
- (BOOL) pushQueryToFront: (id _Nullable)anQuery;

- (void) pauseQueryForIssuedId: (int32_t)issuedId;
- (void) pauseAllQueriesForExecutorName: (NSString * _Nullable)executorName;
- (void) resumeQueryForIssuedId: (int32_t)issuedId;
- (void) resumeAllQueriesForExecutorName: (NSString * _Nullable)executorName;
- (void) resumeAllQueries;

- (void) cancelQueryForIssuedId: (int32_t)issuedId;
- (void) cancelAllQueriesForExecutorName: (NSString * _Nullable)executorName;
- (void) cancelAllQueries;
- (void) expireQuery: (id _Nullable)anQuery;

- (BOOL) isStarted;
- (BOOL) isRunning;
- (BOOL) isPaused;

- (id _Nullable) cacheDataForKey: (NSString * _Nullable)key;
- (BOOL) setCacheData: (id _Nullable)anData forKey: (NSString * _Nullable)key;
- (void) removeCacheDataForKey: (NSString * _Nullable)key;
- (void) removeAllCacheData;

@property (nonatomic, weak) id _Nullable delegate;

@end
