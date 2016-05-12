//
//  Hydra.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>
#import <Hydra/HYQuery.h>
#import <Hydra/HYResult.h>
#import <Hydra/HYTrackingResultSet.h>
#import <Hydra/HYAsyncTask.h>
#import <Hydra/HYExecuter.h>
#import <Hydra/HYWorker.h>
#import <Hydra/HYMigrator.h>
#import <Hydra/HYManager.h>


#define		kHydraDefaultName				@"__THE_LERNAEAN_HYDRA__"


#define		HydraNotification				@"hydraNotification"

#define		HydraNotifiationCodeKey						@"hydraNotificationCodeKey"

typedef enum _HydraNotificationCode_
{
	HydraNotificationCodeMigrationWillInitialing,
	HydraNotificationCodeMigrationDidInitialing,
	HydraNotificationCodeMigrationFailedAtInitialing,
    HydraNotificationCodeMigrationDidStart,
	HydraNotificationCodeMigrationWillStep,
	HydraNotificationCodeMigrationDidStep,
	HydraNotificationCodeMigrationFailedAtStep,
	HydraNotificationCodeMigrationDone,
	HydraNotificationCodeMigrationNothingToDo,
	HydraNotificationCodeDidStartWorker,
	HydraNotificationCodeDidPauseWorker,
	HydraNotificationCodeDidResumeWorker,
	HydraNotificationCodeDidStopWorker,
	
	kCountOfHydraNotificationCode
	
} HydraNotificationCode;

#define		HydraNotificationWorkerNameKey				@"hydraNotificationWorkerNameKey"
#define		HydraNotificationMigrationSuggestNumber		@"hydraNotificationMigrationSuggestNumber"
#define		HydraNotificationMigrationReferenceNumber	@"hydraNotificationMigrationReferenceNumber"


@interface Hydra : NSObject <HYWorkerDelegate>
{
	NSString				*_name;
	
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

// public methods.

+ (Hydra *) defaultHydra;
+ (void) destroyDefaultHydra;

- (BOOL) doMigration: (id)migration waitUntilDone: (BOOL)waitUntilDone;

- (BOOL) addCommonWorker;
- (BOOL) addNormalWorkerForName: (NSString *)name;
- (BOOL) addWorker: (id)anWorker;
- (void) removeWorkerForName: (NSString *)name;
- (id) workerForName: (NSString *)name;

- (void) startAllWorkers;
- (void) startWorkerForName: (NSString *)name;
- (void) pauseAllWorkers;
- (void) pauseWorkerForName: (NSString *)name;
- (void) resumeAllWorkers;
- (void) resumeWorkerForName: (NSString *)name;
- (void) stopAllWorkers;
- (void) stopWorkerForName: (NSString *)name;

- (BOOL) pushQuery: (id)anQuery;

- (void) pauseQueryForIssuedId: (int32_t)issuedId;
- (void) pauseAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName;
- (void) resumeQueryForIssuedId: (int32_t)issuedId;
- (void) resumeAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName;
- (void) resumeAllQueries;

- (void) cancelQueryForIssuedId: (int32_t)issuedId;
- (void) cancelAllQueriesForExecutorName: (NSString *)executorName atWorkerName: (NSString *)workerName;
- (void) cancelAllQueriesForWorkerName: (NSString *)workerName;
- (void) cancelAllQueries;

- (BOOL) setTrackingResultSet: (id)anTrackingResultSet;
- (void) removeTrackingResultSetForName: (NSString *)name;

- (id) cacheDataAtWorker: (NSString *)name forKey: (NSString *)key;
- (BOOL) setCacheData: (id)anData atWoker: (NSString *)name forKey: (NSString *)key;
- (void) removeCacheDataAtWorker: (NSString *)name forKey: (NSString *)key;
- (void) removeAllCacheDataAtWorker: (NSString *)name;

- (id) sharedDataForKey: (NSString *)key;
- (BOOL) setSharedData: (id)anData forKey: (NSString *)key;
- (void) removeSharedDataForKey: (NSString *)key;
- (void) removeAllSharedData;

- (BOOL) bindAsyncTask: (id)anAsyncTask;
- (void) unbindAsyncTaskForIssuedId: (int32_t)issuedId;
- (void) unbindAllAsyncTasks;
- (void) pauseAsyncTaskForIssuedId: (int32_t)issuedId;
- (void) resumeAsyncTaskForIssuedId: (int32_t)issuedId;
- (void) resumeAllAsyncTasks;

@property (nonatomic, readonly) NSString *name;

@end
