//
//  SampleExecutor.m
//  Sample03_UsingAsyncTask
//
//  Created by Tae Hyun Na on 2015. 2. 20.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleExecutor.h"
#import "SampleAsyncTask.h"

@implementation SampleExecutor

- (NSString *)name
{
	return SampleExecutorName;
}

- (BOOL) calledExecutingWithQuery: (id)anQuery
{
	if( [[anQuery parameterForKey: SampleExecutorParameterKeyCloseQueryCall] boolValue] == YES ) {
		
		// prepare result
		HYResult *result = [HYResult resultWithName:self.name];
		[result setParametersFromDictionary:[anQuery paramDict]];
		UIImage *image;
		if( (image = [anQuery parameterForKey:SampleAsyncTaskParameterKeyImage]) != nil ) {
			[result setParameter:image forKey:SampleExecutorParameterKeyImage];
		}
		
		// stored result will notify by name 'SampleExecutorName'
		[self storeResult:result];
		
	} else {
		
		// check parameter
		id anObject = [anQuery parameterForKey:SampleExecutorParameterKeyUrlString];
		if( [anObject isKindOfClass:[NSString class]] == NO ) {
			return NO;
		}
		
		// mark 'close query call' for distinguish query from 'SampleAsyncTask'
		[anQuery setParameter:@"Y" forKey:SampleExecutorParameterKeyCloseQueryCall];
		
		// prepare asynctask object
		SampleAsyncTask *sampleAsyncTask;
		if( (sampleAsyncTask = [[SampleAsyncTask alloc] initWithCloseQuery: anQuery]) == nil ) {
			return NO;
		}
		// if you want to limit for the maximum count of activing asyncTask, you can use 'activeLimiterName' method.
		// asyncTask will grouped by name and active under limit count by queue structure.
		// if not specified active limiter name then it'll active as possible as under system limitation.
		[sampleAsyncTask activeLimiterName:@"bySampleExeutor" withCount:5 byOrder:HYAsyncTaskActiveOrderToFirst];
		// set url string parameter for 'SampleAsyncTask'
		[sampleAsyncTask setParameter:(NSString *)anObject forKey:SampleAsyncTaskParameterKeyUrlString];
		// bind it
		[self bindAsyncTask:sampleAsyncTask];
		
	}
	
	return YES;
}

@end
