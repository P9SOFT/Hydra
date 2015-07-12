//
//  SampleManager.h
//  Sample04_UsingTrackingResultSet
//
//  Created by Tae Hyun, Na on 2015. 3. 10..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
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

- (BOOL)boo;
- (BOOL)foo;

@property (nonatomic, readonly) BOOL standby;

@end
