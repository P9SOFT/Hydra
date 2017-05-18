//
//  SampleManager.h
//  Sample04_UsingTrackingResultSet
//
//  Created by Tae Hyun Na on 2012. 3. 10.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <Hydra/Hydra.h>

#define		SampleManagerNotification					@"sampleManagerNotification"
#define		SampleManagerNotifyParameterKeyOperation			@"sampleManagerNotifyParameterKeyOperation"

typedef enum _SampleManagerOperation_
{
	SampleManagerOperationDummy,
	SampleManagerOperationBoo,
	SampleManagerOperationFoo,
	SampleManagerOperationBooAndFooAllUpdated,
	
} SampleManagerOperation;

@interface SampleManager : HYManager

+ (SampleManager *)defaultManager;
- (BOOL)standbyWithWorkerName:(NSString *)workerName;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL boo;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL foo;

@property (nonatomic, readonly) BOOL standby;

@end
