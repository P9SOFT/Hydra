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

@synthesize useBackgroundThread = _useBackgroundThread;

- (id) init
{
	if( (self = [super init]) != nil ) {
        if( [[self class] performSelector:@selector(suggestedMigrationNumber)] < 1 ) {
			return nil;
		}
	}
	
	return self;
}

+ (NSUInteger) countOfToDoMigration
{
    NSUInteger  suggested = [[self class] performSelector:@selector(suggestedMigrationNumber)];
    NSUInteger  lastUpdated = [[self class] performSelector:@selector(lastUpdatedMigrationNumber)];
    
    return (suggested - lastUpdated);
}

+ (NSUInteger) lastUpdatedMigrationNumber
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: [[self class] migrationNumberKeyString]] unsignedIntegerValue];
}

+ (NSString *) migrationNumberKeyString
{
	// override me, if need :)
	return kDefaultMigrationNumberKey;
}

+ (NSUInteger) suggestedMigrationNumber
{
    // override me, if need :)
    return 1;
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
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithUnsignedInteger: 1] forKey: [[self class] migrationNumberKeyString]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) stepMigrationForNumber: (NSUInteger)migrationNumber
{
	if( [self doMigrationForNumber: migrationNumber] == YES ) {
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithUnsignedInteger: migrationNumber] forKey: [[self class] migrationNumberKeyString]];
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
    desc = [desc stringByAppendingFormat: @"<last_updated_migration_number>%lu</last_updated_migration_number>", [[self class] lastUpdatedMigrationNumber]];
    desc = [desc stringByAppendingFormat: @"<suggested_migration_number>%lu</suggested_migration_number>", [[self class] suggestedMigrationNumber]];
	desc = [desc stringByAppendingString: @"</migrator>"];
	
	return desc;
}


@end
