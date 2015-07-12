//
//  HYMigrator.m
//  Hydra
//
//  Created by Na Tae Hyun on 13. 8. 30..
//  Copyright (c) 2012년 Na Tae Hyun. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYMigrator.h"


#define		kDefaultMigrationNumberKey		@"HYMigrationDefaultMigrationNumberKey"


@implementation HYMigrator

@synthesize useBackgroundThread = _useBackgroundThread;
@synthesize lastUpdatedMigrationNumber = _lastUpdatedMigrationNumber;

- (id) init
{
	if( (self = [super init]) != nil ) {
		_lastUpdatedMigrationNumber = [[[NSUserDefaults standardUserDefaults] objectForKey: [self migrationNumberKeyString]] unsignedIntegerValue];
		if( [self suggestedMigrationNumber] < 1 ) {
			return nil;
		}
	}
	
	return self;
}

- (NSString *) migrationNumberKeyString
{
	// override me, if need :)
	return kDefaultMigrationNumberKey;
}

- (BOOL) doInitialing
{
	// override me, if need :)
	return YES;
}

- (NSUInteger) suggestedMigrationNumber
{
	// override me, if need :)
	return 1;
}

- (BOOL) isSomethingToDoForMigrationNumber: (NSUInteger)migrationNumber
{
	// override me, if need :)
	return NO;
}

- (BOOL) doMigrationForNumber: (NSUInteger)migrationNumber
{
	// override me, if need :)
	return NO;
}

- (NSUInteger) countOfToDoMigration
{
	return ([self suggestedMigrationNumber] - [self lastUpdatedMigrationNumber]);
}

- (void) initialingDone
{
	_lastUpdatedMigrationNumber = 1;
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithUnsignedInteger: 1] forKey: [self migrationNumberKeyString]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) stepMigrationForNumber: (NSUInteger)migrationNumber
{
	if( [self doMigrationForNumber: migrationNumber] == YES ) {
		_lastUpdatedMigrationNumber = migrationNumber;
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithUnsignedInteger: migrationNumber] forKey: [self migrationNumberKeyString]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		return YES;
	}
	
	return NO;
}

- (NSString *) description
{
	NSString	*desc;
	
	desc = [NSString stringWithFormat: @"<migrator>"];
	desc = [desc stringByAppendingFormat: @"<migration_number_key>%@</migration_number_key>", [self migrationNumberKeyString]];
    desc = [desc stringByAppendingFormat: @"<last_updated_migration_number>%lu</last_updated_migration_number>", (unsigned long)_lastUpdatedMigrationNumber];
    desc = [desc stringByAppendingFormat: @"<suggested_migration_number>%lu</suggested_migration_number>", (unsigned long)[self suggestedMigrationNumber]];
	desc = [desc stringByAppendingString: @"</migrator>"];
	
	return desc;
}


@end
