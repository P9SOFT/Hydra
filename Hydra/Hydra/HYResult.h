//
//  HYResult.h
//  Hydra
//
//  Created by  Na Tae Hyun on 12. 5. 2..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYResult : NSObject
{
	int32_t					_issuedId;
	int32_t					_issuedIdOfQuery;
	NSString				*_name;
	NSMutableDictionary		*_paramDict;
	BOOL					_automaticallyMadeByTimeout;
}

// public methods.

+ (HYResult *) resultWithName: (NSString *)name;
- (id) initWithName: (NSString *)name;

- (id) parameterForKey: (NSString *)key;
- (void) setParameter: (id)anObject forKey: (NSString *)key;
- (void) setParametersFromDictionary: (NSDictionary *)dict;
- (void) removeParameterForKey: (NSString *)key;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) int32_t issuedId;
@property (nonatomic, assign) int32_t issuedIdOfQuery;
@property (nonatomic, readonly) BOOL automaticallyMadeByTimeout;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) markAutomaticallyMadeByTimeout;

@property (nonatomic, readonly) NSMutableDictionary *paramDict;

@end
