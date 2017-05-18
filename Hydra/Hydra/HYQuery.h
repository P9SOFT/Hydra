//
//  HYQuery.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYQuery : NSObject

// public methods.

+ (HYQuery * _Nullable) queryWithWorkerName: (NSString * _Nullable)workerName executerName: (NSString * _Nullable)executerName;
- (instancetype _Nullable) initWithWorkerName: (NSString * _Nullable)workerName executerName: (NSString * _Nullable)executerName NS_DESIGNATED_INITIALIZER;

- (id _Nullable) parameterForKey: (NSString * _Nullable)key;
- (void) setParameter: (id _Nullable)anObject forKey: (NSString * _Nullable)key;
- (void) setParametersFromDictionary: (NSDictionary * _Nullable)dict;
- (void) removeParameterForKey: (NSString * _Nullable)key;

- (BOOL) setWaitingResultName: (NSString * _Nullable)resultName withTimeoutInterval: (NSTimeInterval)timeoutInterval skipMeIfAlreadyWaiting: (BOOL)skipMeIfAlreadyWaiting;
- (void) clearWaitingResult;

@property (nonatomic, readonly) int32_t issuedId;
@property (nonatomic, readonly) NSString * _Nonnull workerName;
@property (nonatomic, readonly) NSString * _Nonnull executerName;
@property (nonatomic, assign) BOOL paused;

// these methods are used for internal handling.
// you may not need to using these methods directly.

@property (nonatomic, readonly) NSMutableDictionary * _Nonnull paramDict;
@property (nonatomic, readonly) NSString * _Nullable waitingResultName;
@property (nonatomic, readonly) NSTimeInterval waitingTimeoutInterval;
@property (nonatomic, readonly) BOOL skipMeIfAlreadyWaiting;
@property (nonatomic, readonly) BOOL haveWaitingResult;
@property (nonatomic, assign) int32_t issuedIdOfAsyncTask;
@property (nonatomic, readonly) BOOL haveAsyncTask;
@property (nonatomic, assign) BOOL canceled;

@end
