//
//  HYManager.h
//  Hydra
//
//  Created by Tae Hyun Na on 2013. 8. 30.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>
#import <Hydra/HYQuery.h>
#import <Hydra/HYResult.h>


@interface HYManager : NSObject
{
	BOOL					_binded;
	NSLock					*_lockForExecutorManaging;
	NSMutableDictionary		*_usingExecutorDict;
	NSMutableDictionary		*_workerNameForExecutorDict;
	NSMutableDictionary		*_selectorForExecutorDict;
	NSMutableDictionary		*_usingWorkerNameDict;
}

// you must override and implement these methods.

- (NSString *) name;

// public methods.

- (BOOL) registExecuter: (id)anExecuter withWorkerName: (NSString *)workerName action: (SEL)selector;
- (BOOL) bindToHydra: (id)hydra;

- (HYQuery *) queryForExecutorName: (NSString *)executorName;
- (NSString *) employedWorkerNameForExecutorName: (NSString *)executorName;

@property (nonatomic, readonly) BOOL binded;

// override these methods if need.

- (NSString *) brief;
- (NSString *) customDataDescription;

- (BOOL) didInit;
- (void) willDealloc;
- (BOOL) willBind;
- (void) didBind;

- (NSDictionary *) notifyParametersForResult: (HYResult *)result fromExecutorName: (NSString *)executorName;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) workerReport: (NSNotification *)notification;
- (void) postNotifyWithParamDict: (NSDictionary *)paramDict;

@end
