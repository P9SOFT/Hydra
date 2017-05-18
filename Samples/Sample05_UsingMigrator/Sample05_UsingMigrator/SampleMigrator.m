//
//  SampleMigrator.m
//  Sample05_UsingMigrator
//
//  Created by Tae Hyun Na on 2012. 3. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleMigrator.h"

@implementation SampleMigrator

+ (NSString *) migrationNumberKeyString
{
    return kSampleMigrationNumberKey;
}

- (BOOL)doInitialing
{
	// do something when first initialing task at once
	return YES;
}

+ (NSNumber *)suggestedMigrationNumber
{
	// set last version number of migration to 5 for example.
	return @(5);
}

- (BOOL)isSomethingToDoForMigrationNumber:(NSUInteger)migrationNumber
{
	// check migration number and do some task for given migration number.
	// if something to do for given migration number then return YES, or if not return NO.
	return YES;
}

- (BOOL)doMigrationForNumber:(NSUInteger)migrationNumber
{
	// if you return YES at method 'isSomethingToDoForMigrationNumber:' for given number then,
	// this method called for do migration task.
	// implement your migration code for given number here.
	return YES;
}

@end
