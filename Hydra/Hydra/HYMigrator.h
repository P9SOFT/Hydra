//
//  HYMigrator.h
//  Hydra
//
//  Created by Tae Hyun Na on 2013. 8. 30.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Hydra/HYDefine.h>


typedef NS_ENUM(NSInteger, HYMigratorStatus)
{
	HYMigratorStatusWillStart,
	HYMigratorStatusWillStep,
	HYMigratorStatusDidStep,
	HYMigratorStatusFailedAtStep,
	HYMigratorStatusDone
};


@interface HYMigrator : NSObject

// public methods.

+ (NSNumber * _Nonnull) countOfToDoMigration;
+ (NSNumber * _Nonnull) lastUpdatedMigrationNumber;

// override these methods if need.

+ (NSString * _Nullable) migrationNumberKeyString;
+ (NSNumber * _Nullable) suggestedMigrationNumber;

- (BOOL) doInitialing;
- (BOOL) isSomethingToDoForMigrationNumber: (NSUInteger)migrationNumber;
- (BOOL) doMigrationForNumber: (NSUInteger)migrationNumber;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) initialingDone;
- (BOOL) stepMigrationForNumber: (NSUInteger)migrationNumber;

@property (nonatomic, assign) BOOL useBackgroundThread;

@end
