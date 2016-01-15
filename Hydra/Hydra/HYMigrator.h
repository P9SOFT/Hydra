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


typedef enum _HYMigratorStatus_
{
	HYMigratorStatusWillStart,
	HYMigratorStatusWillStep,
	HYMigratorStatusDidStep,
	HYMigratorStatusFailedAtStep,
	HYMigratorStatusDone,
	kCountOfHYMigratorStatus
	
} HYMigratorStatus;


@interface HYMigrator : NSObject
{
	BOOL			_useBackgroundThread;
	NSUInteger		_lastUpdatedMigrationNumber;
}

// public methods.

- (NSUInteger) countOfToDoMigration;

@property (nonatomic, readonly) NSUInteger lastUpdatedMigrationNumber;

// override these methods if need.

- (NSString *) migrationNumberKeyString;

- (BOOL) doInitialing;

- (NSUInteger) suggestedMigrationNumber;
- (BOOL) isSomethingToDoForMigrationNumber: (NSUInteger)migrationNumber;
- (BOOL) doMigrationForNumber: (NSUInteger)migrationNumber;

// these methods are used for internal handling.
// you may not need to using these methods directly.

- (void) initialingDone;
- (BOOL) stepMigrationForNumber: (NSUInteger)migrationNumber;

@property (nonatomic, assign) BOOL useBackgroundThread;

@end
