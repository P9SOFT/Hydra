//
//  HYExecuter.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYExecuter : NSObject

// you must override and implement these methods.

- (NSString * _Nullable) name;

// public methods for local scope data.

- (void) storeResult: (id _Nullable)anResult;
- (void) removeResultForName: (NSString * _Nullable)resultName;
- (void) clearAllResults;
- (NSString * _Nullable) nameOfEmployedWorker;
- (NSString * _Nullable) nameOfEmployedHydra;
- (BOOL) bindAsyncTask: (id _Nullable)anAsyncTask;
- (BOOL) canIKeepGoingWithQuery: (id _Nullable)anQuery;

// public methods for worker scope data.

- (id _Nullable) workerCacheDataForKey: (NSString * _Nullable)key;
- (BOOL) setWorkerCacheData: (id _Nullable)anData forKey: (NSString * _Nullable)key;
- (void) removeWorkerCacheDataForKey: (NSString * _Nullable)key;
- (void) removeAllWorkerCacheData;

// public methods for hydra scope data.

- (id _Nullable) sharedDataForKey: (NSString * _Nullable)key;
- (BOOL) setSharedData: (id _Nullable)anData forKey: (NSString * _Nullable)key;
- (void) removeSharedDataForKey: (NSString * _Nullable)key;
- (void) removeAllSharedData;

// override these methods if need.

- (NSString * _Nullable) brief;
- (NSString * _Nullable) customDataDescription;

- (BOOL) shouldSkipExecutingWithQuery: (id _Nullable)anQuery;
- (BOOL) calledExecutingWithQuery: (id _Nullable)anQuery;
- (BOOL) calledCancelingWithQuery: (id _Nullable)anQuery;
- (BOOL) calledSkippingWithQuery: (id _Nullable)anQuery;
- (id _Nullable) resultForExpiredQuery: (id _Nullable)anQuery;
- (BOOL) useCustomPostNotification;
- (void) calledCustomPostNotificationForResult: (id _Nullable)anResult;
- (BOOL) queryWillPause: (id _Nullable)anQuery;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (BOOL) executeWithQuery: (id _Nullable)anQuery;
- (BOOL) cancelWithQuery: (id _Nullable)anQuery;
- (BOOL) skipWithQuery: (id _Nullable)anQuery;
- (void) doCustomPostNotificationForResultDict: (NSDictionary * _Nullable)resultDict;
- (BOOL) restoreQueryToQueue: (id _Nullable)anQuery;

@property (nonatomic, weak) id _Nullable employedWorker;
@property (nonatomic, readonly) NSDictionary * _Nonnull resultDict;

@end
