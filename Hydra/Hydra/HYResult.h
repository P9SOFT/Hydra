//
//  HYResult.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYResult : NSObject

// public methods.

+ (HYResult * _Nullable) resultWithName: (NSString * _Nullable)name;
- (instancetype _Nullable) initWithName: (NSString * _Nullable)name NS_DESIGNATED_INITIALIZER;

- (id _Nullable) parameterForKey: (NSString * _Nullable)key;
- (void) setParameter: (id _Nullable)anObject forKey: (NSString * _Nullable)key;
- (void) setParametersFromDictionary: (NSDictionary * _Nullable)dict;
- (void) removeParameterForKey: (NSString * _Nullable)key;

@property (nonatomic, readonly) NSString * _Nonnull name;
@property (nonatomic, readonly) int32_t issuedId;
@property (nonatomic, assign) int32_t issuedIdOfQuery;
@property (nonatomic, readonly) BOOL automaticallyMadeByTimeout;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) markAutomaticallyMadeByTimeout;

@property (nonatomic, readonly) NSMutableDictionary * _Nonnull paramDict;

@end
