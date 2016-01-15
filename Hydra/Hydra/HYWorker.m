//
//  HYWorker.m
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYQuery.h"
#import "HYResult.h"
#import "HYAsyncTask.h"
#import "HYExecuter.h"
#import "HYWorker.h"
#import "Hydra.h"


enum HYWorkerState {
	kHYWorkerStateNull,
	kHYWorkerStateStopped,
	kHYWorkerStateRunning,
	kHYWorkerStatePaused,
	kCountOfHYWorkerState
};


@interface HYWorker( HYWorkerPrivate )

- (NSUInteger) countOfQueriesInQueue;
- (void) pushQueryToQueue: (id)anQuery toFront: (BOOL)toFront;
- (id) popQueryFromQueue;
- (BOOL) postNotifyStarted;
- (BOOL) postNotifyPaused;
- (BOOL) postNotifyResumed;
- (BOOL) postNotifyStopped;
- (BOOL) postNotifyWithResultDict: (NSDictionary *)resultDict;
- (void) fetcher: (id)anParamter;

@end


@implementation HYWorker

@synthesize delegate = _delegate;

- (id) init
{
	if( (self = [super init]) != nil ) {
		if( [[self name] length] <= 0 ) {
			return nil;
		}
		if( (_executerDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_queryQueue = [[NSMutableArray alloc] init]) == nil ) {
			return nil;
		}
		if( (_condition = [[NSCondition alloc] init]) == nil ) {
			return nil;
		}
		_currentState = kHYWorkerStateStopped;
		_nextState = kHYWorkerStateNull;
		if( (_cacheDict = [[NSMutableDictionary alloc] init]) == nil ) {
			return nil;
		}
		if( (_lockForCacheDict = [[NSLock alloc] init]) == nil ) {
			return nil;
		}
		if( [self didInit] == NO ) {
			return nil;
		}
	}
	
	return self;
}

- (id)initWithCommonWorker
{
    if( (self = [super init]) != nil ) {
        _name = HydraCommonWorkerName;
        if( (_executerDict = [[NSMutableDictionary alloc] init]) == nil ) {
            return nil;
        }
        if( (_queryQueue = [[NSMutableArray alloc] init]) == nil ) {
            return nil;
        }
        if( (_condition = [[NSCondition alloc] init]) == nil ) {
            return nil;
        }
        _currentState = kHYWorkerStateStopped;
        _nextState = kHYWorkerStateNull;
        if( (_cacheDict = [[NSMutableDictionary alloc] init]) == nil ) {
            return nil;
        }
        if( (_lockForCacheDict = [[NSLock alloc] init]) == nil ) {
            return nil;
        }
        if( [self didInit] == NO ) {
            return nil;
        }
    }
    
    return self;
}

- (void) dealloc
{
	[self willDealloc];
}

- (BOOL) addExecuter: (id)anExecuter
{
	BOOL		returnFlag;
	
	if( [anExecuter isKindOfClass: [HYExecuter class]] == NO ) {
		return NO;
	}
	
	[_condition lock];
	
	if( [_executerDict objectForKey: [anExecuter name]] == nil ) {
		[anExecuter clearAllResults];
		[anExecuter setEmployedWorker: self];
		[_executerDict setObject: anExecuter forKey: [anExecuter name]];
		returnFlag = YES;
	} else {
		returnFlag = NO;
	}
	
	[_condition unlock];
	
	return returnFlag;
}

- (void) removeExecuterForName: (NSString *)name
{
	id			anExecuter;
	
	if( [name length] <= 0 ) {
		return;
	}
	
	[_condition lock];
	
	if( (anExecuter = [_executerDict objectForKey: name]) != nil ) {
		[anExecuter setEmployedWorker: nil];
		[_executerDict removeObjectForKey: name];
	}
	
	[_condition unlock];
}

- (BOOL) startWorker
{
	[_condition lock];
	
	if( (_currentState == kHYWorkerStateStopped) && (_nextState != kHYWorkerStateRunning) ) {
		if( [self willStart] == YES ) {
			_nextState = kHYWorkerStateRunning;
			[NSThread detachNewThreadSelector: @selector(fetcher:) toTarget: self withObject: nil];
		}
	}
	
	[_condition unlock];
	
	return (_nextState == kHYWorkerStateRunning);
}

- (BOOL) pauseWorker
{
	[_condition lock];
	
	[_executingQuery setPaused: YES];
	
	if( (_currentState == kHYWorkerStateRunning) && (_nextState != kHYWorkerStatePaused) ) {
		if( [self willPause] == YES ) {
			_nextState = kHYWorkerStatePaused;
		}
	}
	
	[_condition signal];
	[_condition unlock];
	
	return (_nextState == kHYWorkerStatePaused);
}

- (BOOL) resumeWorker
{
	[_condition lock];
	
	[_executingQuery setPaused: NO];
	
	if( (_currentState == kHYWorkerStatePaused) && (_nextState != kHYWorkerStateRunning) ) {
		if( [self willResume] == YES ) {
			_nextState = kHYWorkerStateRunning;
		}
	}
	
	[_condition signal];
	[_condition unlock];
	
	return (_nextState == kHYWorkerStateRunning);
}

- (BOOL) stopWorker
{
	[_condition lock];
	
	if( _currentState != kHYWorkerStateStopped ) {
		if( [self willStop] == YES ) {
			_nextState = kHYWorkerStateStopped;
		}
	}
	
	[_condition signal];
	[_condition unlock];
	
	return (_nextState == kHYWorkerStateStopped);
}

- (BOOL) pushQuery: (id)anQuery
{
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	[_condition lock];
	
	[self pushQueryToQueue: anQuery toFront: NO];
	
	[_condition signal];
	[_condition unlock];
	
	return YES;
}

- (BOOL) pushQueryToFront: (id)anQuery
{
	if( [anQuery isKindOfClass: [HYQuery class]] == NO ) {
		return NO;
	}
	
	[_condition lock];
	
	[self pushQueryToQueue: anQuery toFront: YES];
	
	[_condition signal];
	[_condition unlock];
	
	return YES;
}

- (void) pauseQueryForIssuedId: (int32_t)issuedId
{
	HYQuery			*query;
	
	if( [_executingQuery issuedId] == issuedId ) {
		[_executingQuery setPaused: YES];
		return;
	}
	
	[_condition lock];
	
	if( [_executingQuery issuedId] == issuedId ) {
		[_executingQuery setPaused: YES];
	} else {
		for( query in _queryQueue ) {
			if( query.issuedId == issuedId ) {
				query.paused = YES;
				break;
			}
		}
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) pauseAllQueriesForExecutorName: (NSString *)executorName
{
	HYQuery			*query;
	
	if( [executorName length] <= 0 ) {
		return;
	}
	
	[_condition lock];
	
	if( [[_executingQuery executerName] isEqualToString: executorName] == YES ) {
		[_executingQuery setPaused: YES];
	}
	
	for( query in _queryQueue ) {
		if( [[query executerName] isEqualToString: executorName] == YES ) {
			query.paused = YES;
		}
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) resumeQueryForIssuedId: (int32_t)issuedId
{
	HYQuery			*query;
	
	[_condition lock];
	
	if( [_executingQuery issuedId] == issuedId ) {
		[_executingQuery setPaused: NO];
	} else {
		for( query in _queryQueue ) {
			if( query.issuedId == issuedId ) {
				query.paused = NO;
				break;
			}
		}
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) resumeAllQueriesForExecutorName: (NSString *)executorName
{
	HYQuery			*query;
	
	if( [executorName length] <= 0 ) {
		return;
	}
	
	[_condition lock];
	
	if( [[_executingQuery executerName] isEqualToString: executorName] == YES ) {
		[_executingQuery setPaused: NO];
	}
	
	for( query in _queryQueue ) {
		if( [[query executerName] isEqualToString: executorName] == YES ) {
			query.paused = NO;
		}
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) resumeAllQueries
{
	HYQuery			*query;
	
	[_condition lock];
	
	[_executingQuery setPaused: NO];
	
	for( query in _queryQueue ) {
		query.paused = NO;
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) cancelQueryForIssuedId: (int32_t)issuedId
{
	HYQuery			*query;
	
	[_condition lock];
	
	if( [_executingQuery issuedId] == issuedId ) {
		[_executingQuery setCanceled: YES];
	} else {
		for( query in _queryQueue ) {
			if( query.issuedId == issuedId ) {
				query.canceled = YES;
				break;
			}
		}
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) cancelAllQueriesForExecutorName: (NSString *)executorName
{
	HYQuery			*query;
	
	if( [executorName length] <= 0 ) {
		return;
	}
	
	[_condition lock];
	
	if( [[_executingQuery executerName] isEqualToString: executorName] == YES ) {
		[_executingQuery setCanceled: YES];
	}
	
	for( query in _queryQueue ) {
		if( [[query executerName] isEqualToString: executorName] == YES ) {
			query.canceled = YES;
		}
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) cancelAllQueries
{
	HYQuery			*query;
	
	[_condition lock];
	
	[_executingQuery setCanceled: YES];
	
	for( query in _queryQueue ) {
		query.canceled = YES;
	}
	
	[_condition signal];
	[_condition unlock];
}

- (void) expireQuery: (id)anQuery
{
	id				anExecuter;
	id				anResult;
	NSDictionary	*resultDict;
	
	if( [self didExpireQuery: anQuery] == NO ) {
		if( (anExecuter = [_executerDict objectForKey: [anQuery executerName]]) != nil ) {
			if( (anResult = [anExecuter resultForExpiredQuery: anQuery]) != nil ) {
				if( [anResult isKindOfClass: [HYResult class]] == YES ) {
					resultDict = [NSDictionary dictionaryWithObject: anResult forKey: [anResult name]];
					if( [anExecuter useCustomPostNotification] == YES ) {
						[anExecuter doCustomPostNotificationForResultDict: resultDict];
					} else {
						[self postNotifyWithResultDict: resultDict];
					}
				}
			}
		}
	}
}

- (BOOL) isStarted
{
	if( (_currentState == kHYWorkerStatePaused) || (_currentState == kHYWorkerStateRunning) ) {
		return YES;
	}
	
	return NO;
}

- (BOOL) isRunning
{
	if( _currentState == kHYWorkerStateRunning ) {
		return YES;
	}
	
	return NO;
}

- (BOOL) isPaused
{
	if( _currentState == kHYWorkerStatePaused ) {
		return YES;
	}
	
	return NO;
}

- (id) cacheDataForKey: (NSString *)key
{
	id		anObject;
	
	if( [key length] <= 0 ) {
		return nil;
	}
	
	[_lockForCacheDict lock];
	
	anObject = [_cacheDict objectForKey: key];
	
	[_lockForCacheDict unlock];
	
	return anObject;
}

- (BOOL) setCacheData: (id)anData forKey: (NSString *)key
{
	if( ([key length] <= 0) || (anData == nil) ) {
		return NO;
	}
	
	[_lockForCacheDict lock];
	
	[_cacheDict setObject: anData forKey: key];
	
	[_lockForCacheDict unlock];
	
	return YES;
}

- (void) removeCacheDataForKey: (NSString *)key
{
	if( [key length] <= 0 ) {
		return;
	}
	
	[_lockForCacheDict lock];
	
	[_cacheDict removeObjectForKey: key];
	
	[_lockForCacheDict unlock];
}

- (void) removeAllCacheData
{
	[_lockForCacheDict lock];
	
	[_cacheDict removeAllObjects];
	
	[_lockForCacheDict unlock];
}

- (NSUInteger) countOfQueriesInQueue
{
	id			anQuery;
	NSUInteger	countOfQueries;
	
	countOfQueries = 0;
	
	for( anQuery in _queryQueue ) {
		if( ([anQuery canceled] == YES) || ([anQuery paused] == NO) ) {
			++ countOfQueries;
		}
	}
	
	return countOfQueries;
}

- (void) pushQueryToQueue: (id)anQuery toFront: (BOOL)toFront
{
	if( toFront == NO ) {
		[_queryQueue addObject: anQuery];
	} else {
		[_queryQueue insertObject: anQuery atIndex: 0];
	}
}

- (id) popQueryFromQueue
{
	id			anQuery;
	NSUInteger	i, count;
	
	count = [_queryQueue count];
	
	for( i=0 ; i<count ; ++i ) {
		anQuery = [_queryQueue objectAtIndex: i];
		if( ([anQuery canceled] == YES) || ([anQuery paused] == NO) ) {
			anQuery = [_queryQueue objectAtIndex: i];
			[_queryQueue removeObjectAtIndex: i];
			return anQuery;
		}
	}
	
	return nil;
}

- (BOOL) postNotifyStarted
{
	NSDictionary		*params;
	
	if( [_delegate respondsToSelector: @selector(workerStarted:)] == NO ) {
		return NO;
	}
	
	if( (params = [[NSDictionary alloc] initWithObjectsAndKeys: self, HYWorkerParameterKeyWorker, nil]) == nil ) {
		return NO;
	}
	
	[_delegate performSelectorOnMainThread: @selector(workerStarted:) withObject: params waitUntilDone: NO];
	
	return YES;
}

- (BOOL) postNotifyPaused
{
	NSDictionary		*params;
	
	if( [_delegate respondsToSelector: @selector(workerPaused:)] == NO ) {
		return NO;
	}
	
	if( (params = [[NSDictionary alloc] initWithObjectsAndKeys: self, HYWorkerParameterKeyWorker, nil]) == nil ) {
		return NO;
	}
	
	[_delegate performSelectorOnMainThread: @selector(workerPaused:) withObject: params waitUntilDone: NO];
	
	return YES;
}

- (BOOL) postNotifyResumed
{
	NSDictionary		*params;
	
	if( [_delegate respondsToSelector: @selector(workerResumed:)] == NO ) {
		return NO;
	}
	
	if( (params = [[NSDictionary alloc] initWithObjectsAndKeys: self, HYWorkerParameterKeyWorker, nil]) == nil ) {
		return NO;
	}
	
	[_delegate performSelectorOnMainThread: @selector(workerResumed:) withObject: params waitUntilDone: NO];
	
	return YES;
}

- (BOOL) postNotifyStopped
{
	NSDictionary		*params;
	
	if( [_delegate respondsToSelector: @selector(workerStarted:)] == NO ) {
		return NO;
	}
	
	if( (params = [[NSDictionary alloc] initWithObjectsAndKeys: self, HYWorkerParameterKeyWorker, nil]) == nil ) {
		return NO;
	}
	
	[_delegate performSelectorOnMainThread: @selector(workerStarted:) withObject: params waitUntilDone: NO];
	
	return YES;
}

- (BOOL) postNotifyWithResultDict: (NSDictionary *)resultDict
{
	NSDictionary		*params;
	
	if( [_delegate respondsToSelector: @selector(workerPostNotifyResult:)] == NO ) {
		return NO;
	}
	
	if( [resultDict count] <= 0 ) {
		return NO;
	}
	
	if( (params = [[NSDictionary alloc] initWithObjectsAndKeys: self, HYWorkerParameterKeyWorker, resultDict, HYWorkerParameterKeyResultDict, nil]) == nil ) {
		return NO;
	}
	
	[_delegate performSelectorOnMainThread: @selector(workerPostNotifyResult:) withObject: params waitUntilDone: NO];
		
	return YES;
}

- (void) fetcher: (id)anParamter
{
    @autoreleasepool {
        
        id	anExecuter;

        [_condition lock];
        _currentState = kHYWorkerStateRunning;
        _nextState = kHYWorkerStateNull;
        [_condition unlock];

        [self didStart];
        [self postNotifyStarted];
        
        while( 1 ) {
            
            @autoreleasepool {
        
                [_condition lock];
                
                _executingQuery = nil;
                
                while( ([self countOfQueriesInQueue] <= 0) || (_currentState == kHYWorkerStatePaused) ) {
                    [_condition wait];
                    if( _nextState != kHYWorkerStateNull ) {
                        _currentState = _nextState;
                        if( _nextState == kHYWorkerStatePaused ) {
                            [self didPause];
                            [self postNotifyPaused];
                        } else if( _nextState == kHYWorkerStateRunning ) {
                            [self didResume];
                            [self postNotifyResumed];
                        }
                        _nextState = kHYWorkerStateNull;
                    }
                    if( _currentState == kHYWorkerStateStopped ) {
                        break;
                    }
                }
                if( _currentState == kHYWorkerStateStopped ) {
                    [_condition unlock];
                    break;
                }
                
                _executingQuery = [self popQueryFromQueue];
                
                [_condition unlock];
                
                if( [_executingQuery canceled] == YES ) {
                    if( [self didCancelQuery: _executingQuery] == NO ) {
                        if( (anExecuter = [_executerDict objectForKey: [_executingQuery executerName]]) != nil ) {
                            if( [anExecuter cancelWithQuery: _executingQuery] == YES ) {
                                if( [anExecuter useCustomPostNotification] == YES ) {
                                    [anExecuter doCustomPostNotificationForResultDict: [anExecuter resultDict]];
                                } else {
                                    [self postNotifyWithResultDict: [anExecuter resultDict]];
                                }
                            }
                            [anExecuter clearAllResults];
                        }
                    }
                } else {
                    if( [self didFetchQuery: _executingQuery] == NO ) {
                        if( (anExecuter = [_executerDict objectForKey: [_executingQuery executerName]]) != nil ) {
                            if( [anExecuter shouldSkipExecutingWithQuery: _executingQuery] == NO ) {
                                if( [anExecuter executeWithQuery: _executingQuery] == YES ) {
                                    if( [anExecuter useCustomPostNotification] == YES ) {
                                        [anExecuter doCustomPostNotificationForResultDict: [anExecuter resultDict]];
                                    } else {
                                        [self postNotifyWithResultDict: [anExecuter resultDict]];
                                    }
                                }
                            } else {
                                if( [anExecuter skipWithQuery: _executingQuery] == YES ) {
                                    if( [anExecuter useCustomPostNotification] == YES ) {
                                        [anExecuter doCustomPostNotificationForResultDict: [anExecuter resultDict]];
                                    } else {
                                        [self postNotifyWithResultDict: [anExecuter resultDict]];
                                    }
                                }
                            }
                            [anExecuter clearAllResults];
                        }
                    }
                }
                if( [_executingQuery haveAsyncTask] == YES ) {
                    [[Hydra defaultHydra] unbindAsyncTaskForIssuedId: [_executingQuery issuedIdOfAsyncTask]];
                }
                
            }
            
        }
        
        [_condition lock];
        _currentState = kHYWorkerStateStopped;
        _nextState = kHYWorkerStateNull;
        [_condition unlock];

        [self didStop];
        [self postNotifyStopped];
        
    }
}

- (NSString *) name
{
	// you must override me :)
	return _name;
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

- (BOOL) willStart
{
	// override me, if need :)
	return YES;
}

- (void) didStart
{
	// override me, if need :)
}

- (BOOL) willPause
{
	// override me, if need :)
	return YES;
}

- (void) didPause
{
	// override me, if need :)
}

- (BOOL) willResume
{
	// override me, if need :)
	return YES;
}

- (void) didResume
{
	// override me, if need :)
}

- (BOOL) willStop
{
	// override me, if need :)
	return YES;
}

- (void) didStop
{
	// override me, if need :)
}

- (BOOL) didFetchQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (BOOL) didCancelQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (BOOL) didExpireQuery: (id)anQuery
{
	// override me, if need :)
	return NO;
}

- (NSString *) description
{
	NSString	*desc;
	NSString	*brief;
	NSString	*name;
	HYExecuter	*executer;
	id			anObject;
	NSString	*key;
	NSString	*dataDescription;
	
	desc = [NSString stringWithFormat: @"<worker name=\"%@\">", [self name]];
	switch( _currentState ) {
		case kHYWorkerStateStopped :
			desc = [desc stringByAppendingString: @"<current_state value=\"stopped\"/>"];
			break;
		case kHYWorkerStatePaused :
			desc = [desc stringByAppendingString: @"<current_state value=\"paused\"/>"];
			break;
		case kHYWorkerStateRunning :
			desc = [desc stringByAppendingString: @"<current_state value=\"running\"/>"];
			break;
		default :
			desc = [desc stringByAppendingString: @"<current_state value=\"null\"/>"];
			break;
	}
	switch( _nextState ) {
		case kHYWorkerStateStopped :
			desc = [desc stringByAppendingString: @"<next_state value=\"stopped\"/>"];
			break;
		case kHYWorkerStatePaused :
			desc = [desc stringByAppendingString: @"<next_state value=\"paused\"/>"];
			break;
		case kHYWorkerStateRunning :
			desc = [desc stringByAppendingString: @"<next_state value=\"running\"/>"];
			break;
		default :
			desc = [desc stringByAppendingString: @"<next_state value=\"null\"/>"];
			break;
	}
	if( (brief = [self brief]) != nil ) {
		desc = [desc stringByAppendingFormat: @"<brief>%@</brief>", brief];
	}
	desc = [desc stringByAppendingFormat: @"<executers>"];
	for( name in _executerDict ) {
		executer = [_executerDict objectForKey: name];
		desc = [desc stringByAppendingFormat: @"%@", executer];
	}
	desc = [desc stringByAppendingString: @"</executers>"];
	desc = [desc stringByAppendingFormat: @"<cached_data>"];
	[_lockForCacheDict lock];
	for( key in _cacheDict ) {
		anObject = [_cacheDict objectForKey: key];
		if( [anObject respondsToSelector: @selector(description)] == YES ) {
			desc = [desc stringByAppendingFormat: @"<key name=\"%@\">", key];
			desc = [desc stringByAppendingFormat: @"%@", anObject];
			desc = [desc stringByAppendingFormat: @"</key>"];
		} else {
			desc = [desc stringByAppendingFormat: @"<key name=\"%@\"/>", key];
		}
	}
	[_lockForCacheDict unlock];
	desc = [desc stringByAppendingString: @"</cached_data>"];
	if( [_delegate respondsToSelector: @selector(name)] == YES ) {
		if( (name = [_delegate name]) != nil ) {
			desc = [desc stringByAppendingFormat: @"<employed name=\"%@\"/>", name];
		}
	}
	if( (dataDescription = [self customDataDescription]) != nil ) {
		desc = [desc stringByAppendingFormat: @"<custom_data_description>%@</custom_data_description>", dataDescription];
	}
	desc = [desc stringByAppendingString: @"</worker>"];
	
	return desc;
}

@end
