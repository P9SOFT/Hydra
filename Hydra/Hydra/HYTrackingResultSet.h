//
//  HYTrackingResultSet.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYTrackingResultSet : NSObject

// public methods.

- (instancetype _Nullable) initWithName: (NSString * _Nullable)name NS_DESIGNATED_INITIALIZER;

- (void) setResultNamesFromArray: (NSArray * _Nullable)resultNames;
- (BOOL) addResultName: (NSString * _Nullable)resultName;
- (void) removeResultName: (NSString * _Nullable)resultName;

@property (nonatomic, readonly) NSString * _Nonnull name;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (BOOL) updateResult: (id _Nullable)anResult;
- (void) clearResultForName: (NSString * _Nullable)resultName;

- (BOOL) refreshed;
- (void) touch;

@property (NS_NONATOMIC_IOSONLY, readonly) NSDictionary * _Nonnull resultDict;

@end
