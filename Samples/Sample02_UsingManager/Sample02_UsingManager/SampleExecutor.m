//
//  SampleExecutor.m
//  Sample02_UsingManager
//
//  Created by Tae Hyun, Na on 2015. 2. 17..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleExecutor.h"

@implementation SampleExecutor

- (NSString *)name
{
	return SampleExecutorName;
}

- (BOOL) calledExecutingWithQuery: (id)anQuery
{
	// check parameter
	id anObject = [anQuery parameterForKey:SampleExecutorParameterKeyUrlString];
	if( [anObject isKindOfClass:[NSString class]] == NO ) {
		return NO;
	}
	
	// prepare result
	HYResult *result = [HYResult resultWithName:self.name];
	[result setParametersFromDictionary:[anQuery paramDict]];
	
	// get parameter value and do job
	NSString *urlString = (NSString *)anObject;
	if( [urlString length] > 0 ) {
		//NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
		NSError *error;
		NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString] options:NSDataReadingUncached error:&error];
		if( data != nil ) {
			UIImage *image = [UIImage imageWithData:data];
			// if got an image successfully then set it to result
			if( image != nil ) {
				[result setParameter:image forKey:SampleExecutorParameterKeyImage];
			}
		}
	}
	
	// stored result will notify by name 'SampleExecutorName'
	[self storeResult:result];
	
	return YES;
}

@end
