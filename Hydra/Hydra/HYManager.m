//
//  HYManager.m
//  Hydra
//
//  Created by Tae Hyun Na on 2013. 8. 30.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYAsyncTask.h"
#import "HYExecuter.h"
#import "HYWorker.h"
#import "HYManager.h"
#import "Hydra.h"


@interface HYManager ()
{
    NSLock					*_lockForExecutorManaging;
    NSMutableDictionary		*_usingExecutorDict;
    NSMutableDictionary		*_workerNameForExecutorDict;
    NSMutableDictionary		*_selectorForExecutorDict;
    NSMutableDictionary		*_usingWorkerNameDict;
}
@end


@implementation HYManager

- (instancetype) init
{
	if( (self = [super init]) != nil ) {
		if( self.name.length <= 0 ) {
			return nil;
		}
		if( (_usingExecutorDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_workerNameForExecutorDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_selectorForExecutorDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_usingWorkerNameDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_lockForExecutorManaging = [[NSLock alloc] init]) == nil ) {
			return nil;
		}
		if( self.didInit == NO ) {
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[self willDealloc];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];	
}

- (NSString *) name
{
	// you must override me :)
	return nil;
}

- (BOOL) registExecuter: (id)anExecuter withWorkerName: (NSString *)workerName action: (SEL)selector
{
	NSValue		*value;
	
	if( [anExecuter isKindOfClass: [HYExecuter class]] == NO ) {
		return NO;
	}
	
	if( workerName.length <= 0 ) {
		return NO;
	}
	
	[_lockForExecutorManaging lock];
	
	_usingExecutorDict[[anExecuter name]] = anExecuter;
	_workerNameForExecutorDict[[anExecuter name]] = workerName;
	if( selector != nil ) {
		if( (value = [NSValue valueWithPointer: selector]) != nil ) {
			_selectorForExecutorDict[[anExecuter name]] = value;
		}
	}
	_usingWorkerNameDict[workerName] = workerName;
	
	[_lockForExecutorManaging unlock];
	
	return YES;
}

- (BOOL) bindToHydra: (id)hydra
{
	id				anExecutor;
	id				anWorker;
	NSString		*executorName;
	NSString		*workerName;
	
	if( [hydra isKindOfClass: [Hydra class]] == NO ) {
		return NO;
	}
	
	if( _binded == YES ) {
		return NO;
	}
	
	for( executorName in _workerNameForExecutorDict ) {
		workerName = _workerNameForExecutorDict[executorName];
		if( [hydra workerForName: workerName] == nil ) {
			return NO;
		}
	}
	
	for( executorName in _workerNameForExecutorDict ) {
		anExecutor = _usingExecutorDict[executorName];
		workerName = _workerNameForExecutorDict[executorName];
		anWorker = [hydra workerForName: workerName];
		if( [anWorker addExecuter: anExecutor] == NO ) {
			return NO;
		}
	}
	
	for( workerName in _usingWorkerNameDict ) {
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(workerReport:) name: workerName object: nil];
	}
	
	_binded = YES;
	
	return _binded;
}

- (HYQuery *) queryForExecutorName: (NSString *)executorName
{
	if( executorName.length <= 0 ) {
		return nil;
	}
	
	if( _usingExecutorDict[executorName] == nil ) {
		return nil;
	}
	
	return [HYQuery queryWithWorkerName: _workerNameForExecutorDict[executorName] executerName: executorName];
}

- (NSString *) employedWorkerNameForExecutorName: (NSString *)executorName
{
	if( executorName.length <= 0 ) {
		return nil;
	}
	
	return _workerNameForExecutorDict[executorName];
}

- (NSString *) brief
{
	// override me, if need :)
	return nil;
}

- (NSString *) customDataDescription
{
	// override me, if need :)
	return nil;
}

- (BOOL) didInit
{
	// override me, if need : )
	return YES;
}

- (void) willDealloc
{
	// override me, if need :)
}

- (BOOL) willBind
{
	// override me, if need : )
	return YES;
}

- (void) didBind
{
	// override me, if need :)
}

- (NSDictionary *) notifyParametersForResult: (HYResult *)result fromExecutorName: (NSString *)executorName
{
	// override me, if need :)
	return nil;
}

- (void) workerReport: (NSNotification *)notification
{
	NSDictionary		*userInfo;
	NSString			*executorName;
	HYResult			*result;
	NSDictionary		*paramDict;
	NSValue				*value;
	SEL					handlerWithResult;
	IMP					imp;
	
	userInfo = notification.userInfo;
	
	for( executorName in _usingExecutorDict ) {
		if( (result = userInfo[executorName]) != nil ) {
			if( (value = _selectorForExecutorDict[executorName]) != nil ) {
				handlerWithResult = value.pointerValue;
				imp = [self methodForSelector:handlerWithResult];
				id (*func)(id, SEL, id) = (void *)imp;
				paramDict = (NSDictionary *)func(self, handlerWithResult, result);
			} else {
				paramDict = [self notifyParametersForResult: result fromExecutorName: executorName];
			}
			if( paramDict != nil ) {
				[self performSelectorOnMainThread: @selector(postNotifyWithParamDict:) withObject: paramDict waitUntilDone: NO];
			}
		}
	}
}

- (void) postNotifyWithParamDict: (NSDictionary *)paramDict
{
	[[NSNotificationCenter defaultCenter] postNotificationName: self.name object: self userInfo: paramDict];
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*brief;
	NSString	*dataDescription;
	NSString	*executorName;
	id			anExecutor;
	
	desc = [NSString stringWithFormat: @"<manager name=\"%@\">", self.name];
	if( (brief = self.brief) != nil ) {
		desc = [desc stringByAppendingFormat: @"<brief>%@</brief>", brief];
	}
	
	if( _usingExecutorDict.count > 0 ) {
		desc = [desc stringByAppendingString: @"<executors>"];
		for( executorName in _usingExecutorDict ) {
			anExecutor = _usingExecutorDict[executorName];
			desc = [desc stringByAppendingFormat: @"%@", anExecutor];
		}
		desc = [desc stringByAppendingString: @"</executors>"];
	}
	
	if( (dataDescription = self.customDataDescription) != nil ) {
		desc = [desc stringByAppendingFormat: @"<custom_data_description>%@</custom_data_description>", dataDescription];
	}
	desc = [desc stringByAppendingString: @"</manager>"];
	
	return desc;
}

@end
