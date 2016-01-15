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
{
	int32_t					_issuedId;
	int32_t					_madeByQueryIssuedId;
	NSString				*_madeByWorkerName;
	NSString				*_madeByExecutorName;
	id						_closeQuery;
	NSString				*_limiterName;
	NSInteger				_limiterCount;
	HYAsyncTaskActiveOrder	_limiterOrder;
	struct timeval			_tvBinded;
	NSLock					*_lock;
	BOOL					_paused;
}

// public methods.

- (id) initWithCloseQuery: (id)anQuery;
- (BOOL) activeLimiterName: (NSString *)name withCount: (NSInteger)count;
- (BOOL) activeLimiterName: (NSString *)name withCount: (NSInteger)count byOrder: (HYAsyncTaskActiveOrder)order;
- (void) deactiveLimiter;
- (void) madeByQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName;
- (id) parameterForKey: (NSString *)key;
- (void) setParameter: (id)anObject forKey: (NSString *)key;
- (void) removeParameterForKey: (NSString *)key;
- (void) pause;
- (void) resume;
- (void) done;

@property (nonatomic, readonly) int32_t issuedId;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) BOOL paused;

// override these methods if need.

- (NSString *) brief;
- (NSString *) customDataDescription;

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
@property (nonatomic, readonly) NSString *madeByWorkerName;
@property (nonatomic, readonly) NSString *madeByExecutorName;
@property (nonatomic, readonly) NSString *limiterName;
@property (nonatomic, readonly) NSInteger limiterCount;
@property (nonatomic, readonly) HYAsyncTaskActiveOrder limiterOrder;
@property (nonatomic, readonly) unsigned int passedMilisecondFromBind;

@end
