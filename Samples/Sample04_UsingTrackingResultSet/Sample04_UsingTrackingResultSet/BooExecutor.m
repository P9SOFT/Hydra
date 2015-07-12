//
//  BooExecutor.m
//  Sample04_UsingTrackingResultSet
//
//  Created by Tae Hyun, Na on 2015. 3. 10..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "BooExecutor.h"

@implementation BooExecutor

- (NSString *)name
{
	return BooExecutorName;
}

- (BOOL) calledExecutingWithQuery: (id)anQuery
{
	// prepare result
	HYResult *result = [HYResult resultWithName:self.name];
	[result setParametersFromDictionary:[anQuery paramDict]];
	
	// stored result will notify by name 'BooExecutorName'
	[self storeResult:result];
	
	return YES;
}

@end
