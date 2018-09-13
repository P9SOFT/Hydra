//
//  HYMigrator.m
//  Hydra
//
//  Created by Tae Hyun Na on 2013. 8. 30.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HYMigrator.h"


#define		kDefaultMigrationNumberKey		@"HYMigrationDefaultMigrationNumberKey"


@implementation HYMigrator

- (instancetype) init
{
	if( (self = [super init]) != nil ) {
        if( [[[self class] performSelector:@selector(suggestedMigrationNumber)] unsignedIntegerValue] < 1 ) {
			return nil;
		}
	}
	
	return self;
}

+ (NSNumber *) countOfToDoMigration
{
    NSNumber *suggested = [[self class] performSelector:@selector(suggestedMigrationNumber)];
    NSNumber *lastUpdated = [[self class] performSelector:@selector(lastUpdatedMigrationNumber)];
    
    return @(suggested.unsignedIntegerValue - lastUpdated.unsignedIntegerValue);
}

+ (NSNumber *) lastUpdatedMigrationNumber
{
    return [[NSUserDefaults standardUserDefaults] objectForKey: [[self class] migrationNumberKeyString]];
}

+ (NSString *) migrationNumberKeyString
{
	// override me, if need :)
	return kDefaultMigrationNumberKey;
}

+ (NSNumber *) suggestedMigrationNumber
{
    // override me, if need :)
    return @(1);
}

- (BOOL) doInitialing
{
	// override me, if need :)
	return YES;
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

- (void) initialingDone
{
	[[NSUserDefaults standardUserDefaults] setObject: @1U forKey: [[self class] migrationNumberKeyString]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) stepMigrationForNumber: (NSUInteger)migrationNumber
{
	if( [self doMigrationForNumber: migrationNumber] == YES ) {
		[[NSUserDefaults standardUserDefaults] setObject: @(migrationNumber) forKey: [[self class] migrationNumberKeyString]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		return YES;
	}
	
	return NO;
}

- (NSString *) description
{
    NSString	*desc;
	
	desc = [NSString stringWithFormat: @"<migrator>"];
	desc = [desc stringByAppendingFormat: @"<migration_number_key>%@</migration_number_key>", [[self class] migrationNumberKeyString]];
    desc = [desc stringByAppendingFormat: @"<last_updated_migration_number>%@</last_updated_migration_number>", [[self class] lastUpdatedMigrationNumber]];
    desc = [desc stringByAppendingFormat: @"<suggested_migration_number>%@</suggested_migration_number>", [[self class] suggestedMigrationNumber]];
	desc = [desc stringByAppendingString: @"</migrator>"];
	
	return desc;
}


@end
