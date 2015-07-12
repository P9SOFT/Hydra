//
//  HYTrackingResultSet.h
//  Hydra
//
//  Created by  Na Tae Hyun on 12. 5. 11..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


@interface HYTrackingResultSet : NSObject
{
	NSString				*_name;
	NSMutableDictionary		*_resultNameDict;
	NSMutableDictionary		*_resultValueDict;
}

// public methods.

- (id) initWithName: (NSString *)name;

- (void) setResultNamesFromArray: (NSArray *)resultNames;
- (BOOL) addResultName: (NSString *)resultName;
- (void) removeResultName: (NSString *)resultName;

@property (nonatomic, readonly) NSString *name;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (BOOL) updateResult: (id)anResult;
- (void) clearResultForName: (NSString *)resultName;

- (BOOL) refreshed;
- (void) touch;

@property (nonatomic, readonly) NSDictionary *resultDict;

@end
