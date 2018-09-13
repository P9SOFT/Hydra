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
#define		HydraNotifiationCodeKey			@"hydraNotificationCodeKey"

typedef NS_ENUM(NSInteger, HydraNotificationCode)
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
	HydraNotificationCodeDidStopWorker
};

#define		HydraNotificationWorkerNameKey				@"hydraNotificationWorkerNameKey"
#define		HydraNotificationMigrationSuggestNumber		@"hydraNotificationMigrationSuggestNumber"
#define		HydraNotificationMigrationReferenceNumber	@"hydraNotificationMigrationReferenceNumber"


@interface Hydra : NSObject <HYWorkerDelegate>

// public methods.

+ (Hydra * _Nonnull) defaultHydra;

- (BOOL) doMigration: (id _Nullable)migration waitUntilDone: (BOOL)waitUntilDone;

- (BOOL) addCommonWorker;
- (BOOL) addNormalWorkerForName: (NSString * _Nullable)name;
- (BOOL) addWorker: (id _Nullable)anWorker;
- (void) removeWorkerForName: (NSString * _Nullable)name;
- (id _Nullable) workerForName: (NSString * _Nullable)name;

- (void) startAllWorkers;
- (void) startWorkerForName: (NSString * _Nullable)name;
- (void) pauseAllWorkers;
- (void) pauseWorkerForName: (NSString * _Nullable)name;
- (void) resumeAllWorkers;
- (void) resumeWorkerForName: (NSString * _Nullable)name;
- (void) stopAllWorkers;
- (void) stopWorkerForName: (NSString * _Nullable)name;

- (BOOL) pushQuery: (id _Nullable)anQuery;

- (void) pauseQueryForIssuedId: (int32_t)issuedId;
- (void) pauseAllQueriesForExecutorName: (NSString * _Nullable)executorName atWorkerName: (NSString * _Nullable)workerName;
- (void) resumeQueryForIssuedId: (int32_t)issuedId;
- (void) resumeAllQueriesForExecutorName: (NSString * _Nullable)executorName atWorkerName: (NSString * _Nullable)workerName;
- (void) resumeAllQueries;

- (void) cancelQueryForIssuedId: (int32_t)issuedId;
- (void) cancelAllQueriesForExecutorName: (NSString * _Nullable)executorName atWorkerName: (NSString * _Nullable)workerName;
- (void) cancelAllQueriesForWorkerName: (NSString * _Nullable)workerName;
- (void) cancelAllQueries;

- (BOOL) setTrackingResultSet: (id _Nullable)anTrackingResultSet;
- (void) removeTrackingResultSetForName: (NSString * _Nullable)name;

- (id _Nullable) cacheDataAtWorker: (NSString * _Nullable)name forKey: (NSString * _Nullable)key;
- (BOOL) setCacheData: (id _Nullable)anData atWoker: (NSString * _Nullable)name forKey: (NSString * _Nullable)key;
- (void) removeCacheDataAtWorker: (NSString * _Nullable)name forKey: (NSString * _Nullable)key;
- (void) removeAllCacheDataAtWorker: (NSString * _Nullable)name;

- (id _Nullable) sharedDataForKey: (NSString * _Nullable)key;
- (BOOL) setSharedData: (id _Nullable)anData forKey: (NSString * _Nullable)key;
- (void) removeSharedDataForKey: (NSString * _Nullable)key;
- (void) removeAllSharedData;

- (BOOL) bindAsyncTask: (id _Nullable)anAsyncTask;
- (void) unbindAsyncTaskForIssuedId: (int32_t)issuedId;
- (void) unbindAllAsyncTasks;
- (void) pauseAsyncTaskForIssuedId: (int32_t)issuedId;
- (void) resumeAsyncTaskForIssuedId: (int32_t)issuedId;
- (void) resumeAllAsyncTasks;

@property (nonatomic, readonly) NSString * _Nonnull name;

@end
