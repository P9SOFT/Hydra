//
//  HYExecuter.h
//  Hydra
//
//  Created by  Na Tae Hyun on 12. 5. 2..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYExecuter : NSObject
{
	__weak id				_employedWorker;
	NSMutableDictionary		*_resultDict;
}

// you must override and implement these methods.

- (NSString *) name;

// public methods for local scope data.

- (void) storeResult: (id)anResult;
- (void) removeResultForName: (NSString *)resultName;
- (void) clearAllResults;
- (NSString *) nameOfEmployedWorker;
- (NSString *) nameOfEmployedHydra;
- (BOOL) bindAsyncTask: (id)anAsyncTask;
- (BOOL) canIKeepGoingWithQuery: (id)anQuery;

// public methods for worker scope data.

- (id) workerCacheDataForKey: (NSString *)key;
- (BOOL) setWorkerCacheData: (id)anData forKey: (NSString *)key;
- (void) removeWorkerCacheDataForKey: (NSString *)key;
- (void) removeAllWorkerCacheData;

// public methods for hydra scope data.

- (id) sharedDataForKey: (NSString *)key;
- (BOOL) setSharedData: (id)anData forKey: (NSString *)key;
- (void) removeSharedDataForKey: (NSString *)key;
- (void) removeAllSharedData;

// override these methods if need.

- (NSString *) brief;
- (NSString *) customDataDescription;

- (BOOL) shouldSkipExecutingWithQuery: (id)anQuery;
- (BOOL) calledExecutingWithQuery: (id)anQuery;
- (BOOL) calledCancelingWithQuery: (id)anQuery;
- (BOOL) calledSkippingWithQuery: (id)anQuery;
- (id) resultForExpiredQuery: (id)anQuery;
- (BOOL) useCustomPostNotification;
- (void) calledCustomPostNotificationForResult: (id)anResult;
- (BOOL) queryWillPause: (id)anQuery;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (BOOL) executeWithQuery: (id)anQuery;
- (BOOL) cancelWithQuery: (id)anQuery;
- (BOOL) skipWithQuery: (id)anQuery;
- (void) doCustomPostNotificationForResultDict: (NSDictionary *)resultDict;
- (BOOL) restoreQueryToQueue: (id)anQuery;

@property (nonatomic, weak) id employedWorker;
@property (nonatomic, readonly) NSDictionary *resultDict;

@end
