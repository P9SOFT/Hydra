//
//  HYAsyncTask.h
//  Hydra
//
//  Created by Tae Hyun Na on 2013. 3. 29.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <sys/time.h>
#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


typedef enum _HYAsyncTaskActiveOrder_
{
	HYAsyncTaskActiveOrderToLast,
	HYAsyncTaskActiveOrderToFirst,
	kCountOfHYAsyncTaskActiveOrder
	
} HYAsyncTaskActiveOrder;


@interface HYAsyncTask : NSObject

// public methods.

- (instancetype _Nullable) initWithCloseQuery: (id _Nullable)anQuery NS_DESIGNATED_INITIALIZER;
- (BOOL) activeLimiterName: (NSString * _Nullable)name withCount: (NSInteger)count;
- (BOOL) activeLimiterName: (NSString * _Nullable)name withCount: (NSInteger)count byOrder: (HYAsyncTaskActiveOrder)order;
- (void) deactiveLimiter;
- (void) madeByQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString * _Nullable)workerName executorName: (NSString * _Nullable)executorName;
- (id _Nullable) parameterForKey: (NSString * _Nullable)key;
- (void) setParameter: (id _Nullable)anObject forKey: (NSString * _Nullable)key;
- (void) removeParameterForKey: (NSString * _Nullable)key;
- (void) pause;
- (void) resume;
- (void) done;

@property (nonatomic, readonly) int32_t issuedId;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) BOOL paused;

// override these methods if need.

- (NSString * _Nullable) brief;
- (NSString * _Nullable) customDataDescription;

- (BOOL) didInit;
- (void) willDealloc;
- (BOOL) didBind;
- (void) willPause;
- (void) willResume;
- (void) willDone;
- (void) willCancel;
- (void) willUnbind;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) cancel;
- (void) bind;
- (void) unbind;

@property (nonatomic, readonly) int32_t madeByQueryIssuedId;
@property (nonatomic, readonly) NSString * _Nullable madeByWorkerName;
@property (nonatomic, readonly) NSString * _Nullable madeByExecutorName;
@property (nonatomic, readonly) NSString * _Nullable limiterName;
@property (nonatomic, readonly) NSInteger limiterCount;
@property (nonatomic, readonly) HYAsyncTaskActiveOrder limiterOrder;
@property (nonatomic, readonly) unsigned int passedMilisecondFromBind;

@end
