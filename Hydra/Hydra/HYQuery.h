//
//  HYQuery.h
//  Hydra
//
//  Created by  Na Tae Hyun on 12. 5. 2..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYQuery : NSObject
{
	int32_t					_issuedId;
	NSString				*_workerName;
	NSString				*_executerName;
	NSMutableDictionary		*_paramDict;
	NSString				*_waitingResultName;
	NSTimeInterval			_waitingTimeoutInterval;
    BOOL                    _skipMeIfAlreadyWaiting;
	BOOL					_haveWaitingResult;
	int32_t					_issuedIdOfAsyncTask;
	BOOL					_haveAsyncTask;
	BOOL					_paused;
	BOOL					_canceled;
}

// public methods.

+ (HYQuery *) queryWithWorkerName: (NSString *)workerName executerName: (NSString *)executerName;
- (id) initWithWorkerName: (NSString *)workerName executerName: (NSString *)executerName;

- (id) parameterForKey: (NSString *)key;
- (void) setParameter: (id)anObject forKey: (NSString *)key;
- (void) setParametersFromDictionary: (NSDictionary *)dict;
- (void) removeParameterForKey: (NSString *)key;

- (BOOL) setWaitingResultName: (NSString *)resultName withTimeoutInterval: (NSTimeInterval)timeoutInterval skipMeIfAlreadyWaiting: (BOOL)skipMeIfAlreadyWaiting;
- (void) clearWaitingResult;

@property (nonatomic, readonly) int32_t issuedId;
@property (nonatomic, readonly) NSString *workerName;
@property (nonatomic, readonly) NSString *executerName;
@property (nonatomic, assign) BOOL paused;

// these methods are used for internal handling.
// you may not need to using these methods directly.

@property (nonatomic, readonly) NSMutableDictionary *paramDict;
@property (nonatomic, readonly) NSString *waitingResultName;
@property (nonatomic, readonly) NSTimeInterval waitingTimeoutInterval;
@property (nonatomic, readonly) BOOL skipMeIfAlreadyWaiting;
@property (nonatomic, readonly) BOOL haveWaitingResult;
@property (nonatomic, assign) int32_t issuedIdOfAsyncTask;
@property (nonatomic, readonly) BOOL haveAsyncTask;
@property (nonatomic, assign) BOOL canceled;

@end
