//
//  SampleManager.h
//  Sample02_UsingManager
//
//  Created by Tae Hyun Na on 2015. 2. 17.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <Hydra/Hydra.h>

#define		SampleManagerNotification					@"sampleManagerNotification"
#define		SampleManagerNotifyParameterKeyOperation			@"sampleManagerNotifyParameterKeyOperation"
#define		SampleManagerNotifyParameterKeyOperandImage			@"sampleManagerNotifyParameterKeyOperandImage"

typedef enum _SampleManagerOperation_
{
	SampleManagerOperationDummy,
	SampleManagerOperationLoadImage
	
} SampleManagerOperation;

@interface SampleManager : HYManager
{
	NSMutableDictionary	*_cachedImageDict;
}

+ (SampleManager *)defaultManager;
- (BOOL)standbyWithWorkerName:(NSString *)workerName;

- (UIImage *)loadImageFromUrlString:(NSString *)urlString;

@property (nonatomic, readonly) BOOL standby;

@end
