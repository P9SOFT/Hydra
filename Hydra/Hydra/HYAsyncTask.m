//
//  HYAsyncTask.m
//  Hydra
//
//  Created by  Na Tae Hyun on 13. 3. 29..
//  Copyright (c) 2013년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYQuery.h"
#import "HYAsyncTask.h"
#import "Hydra.h"


int32_t			g_HYAsyncTask_last_issuedId;


@implementation HYAsyncTask

@synthesize issuedId = _issuedId;
@dynamic running;
@synthesize paused = _paused;
@synthesize madeByQueryIssuedId = _madeByQueryIssuedId;
@synthesize madeByWorkerName = _madeByWorkerName;
@synthesize madeByExecutorName = _madeByExecutorName;
@synthesize limiterName = _limiterName;
@synthesize limiterCount = _limiterCount;
@synthesize limiterOrder = _limiterOrder;
@dynamic passedMilisecondFromBind;

- (id) init
{
	return nil;
}

- (id) initWithCloseQuery: (id)anQuery
{
	if( (self = [super init]) != nil ) {
		if( (anQuery == nil) || ([anQuery isKindOfClass: [HYQuery class]] == NO) ) {
			[self release];
			return nil;
		}
		_closeQuery = [anQuery retain];
		_issuedId = OSAtomicIncrement32( &g_HYAsyncTask_last_issuedId );
		[_closeQuery setIssuedIdOfAsyncTask: _issuedId];
		if( (_lock = [[NSLock alloc] init]) == nil ) {
			[self release];
			return nil;
		}
		if( [self didInit] == NO ) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[self willDealloc];
	
	[_madeByWorkerName release];
	[_madeByExecutorName release];
	[_closeQuery release];
	[_lock release];
	[_limiterName release];
	
	[super dealloc];
}

- (BOOL) activeLimiterName: (NSString *)name withCount: (NSInteger)count
{
	return [self activeLimiterName: name withCount: count byOrder: HYAsyncTaskActiveOrderToLast];
}

- (BOOL) activeLimiterName: (NSString *)name withCount: (NSInteger)count byOrder: (HYAsyncTaskActiveOrder)order
{
	if( ([name length] <= 0) || (count <= 0) ) {
		return NO;
	}
	
	[_limiterName release];
	_limiterName = [name copy];
	
	_limiterCount = count;
	_limiterOrder = order;
	
	return YES;
}

- (void) deactiveLimiter
{
	[_limiterName release];
	_limiterName = nil;
	
	_limiterCount = 0;
}

- (void) madeByQueryIssuedId: (int32_t)queryIssuedId workerName: (NSString *)workerName executorName: (NSString *)executorName
{
	_madeByQueryIssuedId = queryIssuedId;
	
	[workerName retain];
	[_madeByWorkerName release];
	_madeByWorkerName = workerName;
	
	[executorName retain];
	[_madeByExecutorName release];
	_madeByExecutorName = executorName;
}

- (id) parameterForKey: (NSString *)key
{
	return [_closeQuery parameterForKey: key];
}

- (void) setParameter: (id)anObject forKey: (NSString *)key
{
	[_closeQuery setParameter: anObject forKey: key];
}

- (void) removeParameterForKey: (NSString *)key
{
	[_closeQuery removeParameterForKey: key];
}

- (void) pause
{
	[_lock lock];
	if( _paused == YES ) {
		[_lock unlock];
		return;
	}
	_paused = YES;
	[_lock unlock];
	
	[self willPause];
}

- (void) resume
{
	[_lock lock];
	if( _paused == NO ) {
		[_lock unlock];
		return;
	}
	_paused = NO;
	[_lock unlock];
	
	[self willResume];
}

- (void) done
{
	if( _closeQuery == nil ) {
		return;
	}
	
	[self willDone];
	
	[[Hydra defaultHydra] pushQuery: _closeQuery];
	[_closeQuery release];
	_closeQuery = nil;
}

- (void) cancel
{
	if( _closeQuery == nil ) {
		return;
	}
	
	[self willCancel];
	
	[[Hydra defaultHydra] pushQuery: _closeQuery];
	[_closeQuery release];
	_closeQuery = nil;
}

- (void) bind
{
	if( [self didBind] == NO ) {
		[self done];
	}
	
	gettimeofday( &_tvBinded, NULL );
}

- (void) unbind
{
	[self willUnbind];
}

- (BOOL) running
{
	if( (_tvBinded.tv_sec == 0) && (_tvBinded.tv_usec == 0) ) {
		return NO;
	}
	
	return YES;
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
	// override me, if need :)
	return YES;
}

- (void) willDealloc
{
	// override me, if need :)
}

- (BOOL) didBind
{
	// override me, if need :)
	return YES;
}

- (void) willPause
{
	// override me, if need :)
}

- (void) willResume
{
	// override me, if need :)
}

- (void) willDone
{
	// override me, if need :)
}

- (void) willCancel
{
	// override me, if need :)
}

- (void) willUnbind
{
	// override me, if need :)
}

- (BOOL) isEqual: (id)anObject
{
	if( [anObject isKindOfClass: [HYAsyncTask class]] == NO ) {
		return NO;
	}
	
	return ([self issuedId] == [anObject issuedId]);
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*brief;
	NSString	*dataDescription;
	
	desc = [NSString stringWithFormat: @"<async_task issuedid=\"%d\">", _issuedId];
	if( (brief = [self brief]) != nil ) {
		desc = [desc stringByAppendingFormat: @"<brief>%@</brief>", brief];
	}
	if( (_madeByQueryIssuedId > 0) || ([_madeByWorkerName length] > 0) || ([_madeByExecutorName length] > 0) ) {
		desc = [desc stringByAppendingString: @"<made_by_query"];
		if( _madeByQueryIssuedId > 0 ) {
			desc = [desc stringByAppendingFormat: @" issudedid=\"%d\"", _madeByQueryIssuedId];
		}
		if( [_madeByWorkerName length] > 0 ) {
			desc = [desc stringByAppendingFormat: @" worker=\"%@\"", _madeByWorkerName];
		}
		if( [_madeByExecutorName length] > 0 ) {
			desc = [desc stringByAppendingFormat: @" executor=\"%@\"", _madeByExecutorName];
		}
		desc = [desc stringByAppendingString: @"/>"];
	}
	if( [_limiterName length] > 0 ) {
		desc = [desc stringByAppendingFormat: @"<limiter name=\"%@\" count=\"%ld\" order=\"%d\"/>", _limiterName, (long)_limiterCount, (int)_limiterOrder];
	}
	desc = [desc stringByAppendingFormat: @"<bind sec=\"%ld\" usec=\"%d\"/ paused=\"%@\">", _tvBinded.tv_sec, _tvBinded.tv_usec, [[NSNumber numberWithBool: _paused] stringValue]];
	if( _closeQuery != nil ) {
		desc = [desc stringByAppendingFormat: @"<close_query>%@</close_query>", _closeQuery];
	}
	if( (dataDescription = [self customDataDescription]) != nil ) {
		desc = [desc stringByAppendingFormat: @"<custom_data_description>%@</custom_data_description>", dataDescription];
	}
	desc = [desc stringByAppendingString: @"</async_task>"];
	
	return desc;
}

- (unsigned int) passedMilisecondFromBind
{
	struct timeval	tvNow, tvPassed;
	unsigned int	passed;
	
	gettimeofday( &tvNow, NULL );
	
	timersub( &tvNow, &_tvBinded, &tvPassed );
	
	if( tvPassed.tv_sec < 0 ) {
		return 0;
	}
	
	passed = (unsigned int)(tvPassed.tv_sec * 1000);
	passed += (unsigned int)((float)tvPassed.tv_usec / 1000.0f);
	
	return passed;
}

@end
