//
//  SampleManager.m
//  Sample03_UsingAsyncTask
//
//  Created by Tae Hyun, Na on 2015. 2. 20..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleManager.h"
#import "SampleExecutor.h"

@interface SampleManager (SampleManagerPrivate)

- (NSMutableDictionary *)sampleExecutorHandlerWithResult:(HYResult *)result;

@end

@implementation SampleManager

@synthesize standby = _standby;

- (NSString *) name
{
	return SampleManagerNotification;
}

- (NSString *) brief
{
	return @"Sample manager";
}

- (BOOL) didInit
{
	if( (_cachedImageDict = [[NSMutableDictionary alloc] init]) == nil ) {
		return NO;
	}
	
	return YES;
}

+ (SampleManager *)defaultManager
{
	static dispatch_once_t	once;
	static SampleManager	*sharedInstance;
	
	dispatch_once(&once, ^{ sharedInstance = [[self alloc] init];});
	
	return sharedInstance;
}

- (BOOL)standbyWithWorkerName:(NSString *)workerName
{
	if( (self.standby == YES) || ([workerName length] <= 0) ) {
		return NO;
	}
	
	// regist executor with handling method
	[self registExecuter: [[SampleExecutor alloc] init] withWorkerName:workerName action:@selector(sampleExecutorHandlerWithResult:)];
	
	_standby = YES;
	
	return YES;
}

- (UIImage *)loadImageFromUrlString:(NSString *)urlString
{
	if( self.standby == NO ) {
		return nil;
	}
	if( [urlString length] == 0 ) {
		return nil;
	}
	
	UIImage *image;
	if( (image = [_cachedImageDict objectForKey:urlString]) != nil ) {
		return image;
	}
	
	// make query and push to hydra
	HYQuery *query;
	if( (query = [self queryForExecutorName:SampleExecutorName]) == nil ) {
		return nil;
	}
	[query setParameter:urlString forKey:SampleExecutorParameterKeyUrlString];
	[[Hydra defaultHydra] pushQuery:query];
	
	return nil;
}

- (NSMutableDictionary *)sampleExecutorHandlerWithResult:(HYResult *)result
{
	NSMutableDictionary *paramDict;
	
	if( (paramDict = [[NSMutableDictionary alloc] init]) == nil ) {
		return nil;
	}
	
	// set operation value
	[paramDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)SampleManagerOperationLoadImage] forKey:SampleManagerNotifyParameterKeyOperation];
	
	// set image data if have
	UIImage *image = [result parameterForKey:SampleExecutorParameterKeyImage];
	if( image != nil ) {
		NSString *urlString = [result parameterForKey:SampleExecutorParameterKeyUrlString];
		if( [urlString length] > 0 ) {
			[_cachedImageDict setObject:image forKey:urlString];
		}
		[paramDict setObject:image forKey:SampleManagerNotifyParameterKeyOperandImage];
	}
	
	if( [paramDict count] == 0 ) {
		return nil;
	}
	
	// 'paramDict' will be 'userInfo' of notification, 'SampleManagerNotification'.
	return paramDict;
}

@end
