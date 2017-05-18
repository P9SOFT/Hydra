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

// you must override and implement these methods.

- (NSString * _Nullable) name;

// public methods.

- (BOOL) registExecuter: (id _Nullable)anExecuter withWorkerName: (NSString * _Nullable)workerName action: (SEL _Nullable)selector;
- (BOOL) bindToHydra: (id _Nullable)hydra;

- (HYQuery * _Nullable) queryForExecutorName: (NSString * _Nullable)executorName;
- (NSString * _Nullable) employedWorkerNameForExecutorName: (NSString * _Nullable)executorName;

@property (nonatomic, readonly) BOOL binded;

// override these methods if need.

- (NSString * _Nullable) brief;
- (NSString * _Nullable) customDataDescription;

- (BOOL) didInit;
- (void) willDealloc;
- (BOOL) willBind;
- (void) didBind;

- (NSDictionary * _Nullable) notifyParametersForResult: (HYResult * _Nullable)result fromExecutorName: (NSString * _Nullable)executorName;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) workerReport: (NSNotification * _Nullable)notification;
- (void) postNotifyWithParamDict: (NSDictionary * _Nullable)paramDict;

@end
