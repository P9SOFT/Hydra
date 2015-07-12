//
//  SampleManager.m
//  Sample04_UsingTrackingResultSet
//
//  Created by Tae Hyun, Na on 2015. 3. 10..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleManager.h"
#import "BooExecutor.h"
#import "FooExecutor.h"

#define		kTrackingResultNameForBooAndFooAllUpdated		@"booAndFooAllUpdated"

@interface SampleManager (SampleManagerPrivate)

- (NSMutableDictionary *)booExecutorHandlerWithResult:(HYResult *)result;
- (NSMutableDictionary *)fooExecutorHandlerWithResult:(HYResult *)result;
- (void)booAndFooAllUpdated:(NSNotification *)notification;

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

- (void) willDealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kTrackingResultNameForBooAndFooAllUpdated object:nil];
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
	[self registExecuter: [[BooExecutor alloc] init] withWorkerName:workerName action:@selector(booExecutorHandlerWithResult:)];
	[self registExecuter: [[FooExecutor alloc] init] withWorkerName:workerName action:@selector(fooExecutorHandlerWithResult:)];
	
	// set tracking result set
	HYTrackingResultSet	*trackingResultSet = [[HYTrackingResultSet alloc] initWithName:kTrackingResultNameForBooAndFooAllUpdated];
	[trackingResultSet setResultNamesFromArray:[NSArray arrayWithObjects:BooExecutorName, FooExecutorName, nil]];
	[[Hydra defaultHydra] setTrackingResultSet:trackingResultSet];
	// and add observer to get notify by name of TrackingResultSet
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(booAndFooAllUpdated:) name:kTrackingResultNameForBooAndFooAllUpdated object:nil];
	
	_standby = YES;
	
	return YES;
}

- (BOOL)boo
{
	if( self.standby == NO ) {
		return nil;
	}

	// make query and push to hydra
	HYQuery *query;
	if( (query = [self queryForExecutorName:BooExecutorName]) == nil ) {
		return NO;
	}
	[[Hydra defaultHydra] pushQuery:query];
	
	return YES;
}

- (BOOL)foo
{
	if( self.standby == NO ) {
		return nil;
	}
	
	// make query and push to hydra
	HYQuery *query;
	if( (query = [self queryForExecutorName:FooExecutorName]) == nil ) {
		return NO;
	}
	[[Hydra defaultHydra] pushQuery:query];
	
	return YES;
}

- (NSMutableDictionary *)booExecutorHandlerWithResult:(HYResult *)result
{
	NSMutableDictionary *paramDict;
	
	if( (paramDict = [[NSMutableDictionary alloc] init]) == nil ) {
		return nil;
	}
	
	// set operation value
	[paramDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)SampleManagerOperationBoo] forKey:SampleManagerNotifyParameterKeyOperation];
	
	// 'paramDict' will be 'userInfo' of notification, 'SampleManagerNotification'.
	return paramDict;
}

- (NSMutableDictionary *)fooExecutorHandlerWithResult:(HYResult *)result
{
	NSMutableDictionary *paramDict;
	
	if( (paramDict = [[NSMutableDictionary alloc] init]) == nil ) {
		return nil;
	}
	
	// set operation value
	[paramDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)SampleManagerOperationFoo] forKey:SampleManagerNotifyParameterKeyOperation];
	
	// 'paramDict' will be 'userInfo' of notification, 'SampleManagerNotification'.
	return paramDict;
}

- (void)booAndFooAllUpdated:(NSNotification *)notification
{
	NSDictionary *paramDict = @{SampleManagerNotifyParameterKeyOperation:[NSNumber numberWithUnsignedInteger:(NSUInteger)SampleManagerOperationBooAndFooAllUpdated]};
	[[NSNotificationCenter defaultCenter] postNotificationName:self.name object:self userInfo:paramDict];
}

@end
