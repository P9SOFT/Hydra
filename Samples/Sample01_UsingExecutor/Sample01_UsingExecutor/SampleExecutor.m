//
//  SampleExecutor.m
//  Sample01_UsingExecutor
//
//  Created by Tae Hyun Na on 2015. 2. 17.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleExecutor.h"

@interface SampleExecutor (SampleExecutorPrivate)

- (NSUInteger) factorial:(NSUInteger)factor;

@end

@implementation SampleExecutor

- (NSString *)name
{
	return SampleExecutorName;
}

- (BOOL) calledExecutingWithQuery: (id)anQuery
{
	// check parameter
	id anObject = [anQuery parameterForKey:SampleExecutorParameterKeyInputNumber];
	if( [anObject isKindOfClass:[NSNumber class]] == NO ) {
		return NO;
	}
	
	// get parameter value
	NSUInteger inputNumberValue = [anObject unsignedIntegerValue];
	NSUInteger resultValue;
	
	// prepare result
	HYResult *result = [HYResult resultWithName:self.name];
	// forward input key/value to result. it is useful when you want to reference input key/value at receive handler.
	[result setParametersFromDictionary:[anQuery paramDict]];
	if( inputNumberValue > 32 ) {
		[result setParameter:@"overflowed Input boundary" forKey:SampleExecutorParameterKeyErrorMessage];
	} else {
		resultValue = (inputNumberValue == 0) ? 0 : [self factorial:inputNumberValue];
		[result setParameter:@(resultValue) forKey:SampleExecutorParameterKeyOutputNumber];
	}
	
	// stored result will notify by name 'SampleExecutorName'
	[self storeResult:result];
	
	return YES;
}

- (NSUInteger) factorial:(NSUInteger)factor
{
	if( factor == 1 ) {
		return 1;
	}
	
	return (factor * [self factorial:factor-1]);
}

@end
