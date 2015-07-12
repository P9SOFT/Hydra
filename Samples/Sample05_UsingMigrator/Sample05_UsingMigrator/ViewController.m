//
//  ViewController.m
//  Sample05_UsingMigrator
//
//  Created by Tae Hyun, Na on 2015. 3. 11..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import <Hydra/Hydra.h>
#import "ViewController.h"
#import "SampleMigrator.h"

@interface ViewController (ViewControllerPrivate)

- (void)appendLog:(NSString *)logString;
- (void)touchUpInsideResetButton:(id)sender;
- (void)hydraReport:(NSNotification *)notification;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	_playgroundView = [[PlaygroundView alloc] init];
	_playgroundView.frame = self.view.bounds;
	[self.view addSubview:_playgroundView];
	
	[_playgroundView.resetButton addTarget:self action:@selector(touchUpInsideResetButton:) forControlEvents:UIControlEventTouchUpInside];
	
	// add observer to get notify that progress report of migration.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hydraReport:) name:HydraNotification object:nil];
	
	// load migration module and pass it to hydra to migration.
	SampleMigrator *migrator = [[SampleMigrator alloc] init];
	_playgroundView.suggestedMigrationNumberTextField.text = [[NSNumber numberWithUnsignedInteger:[migrator suggestedMigrationNumber]] stringValue];
	[[Hydra defaultHydra] doMigration:migrator waitUntilDone:NO];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)appendLog:(NSString *)logString
{
	if( [logString length] <= 0 ) {
		return;
	}
	
	NSString *logMessage = [NSString stringWithFormat: @"- %@\n%@", logString, _playgroundView.logView.text];
	_playgroundView.logView.text = logMessage;
	[_playgroundView.logView setScrollsToTop: YES];
}

- (void)touchUpInsideResetButton:(id)sender
{
	// here is hard coding for just showing sample.
	// key "HYMigrationDefaultMigrationNumberKey" is default key of HYMigrator,
	// you could change this key by overiding method 'migrationNumberKeyString' or just use default key.
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HYMigrationDefaultMigrationNumberKey"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)hydraReport:(NSNotification *)notification
{
	NSDictionary				*userInfo;
	HydraNotificationCode		code;
	NSNumber					*suggestNumber;
	NSNumber					*referenceNumber;
	
	userInfo = [notification userInfo];
	
	code = (HydraNotificationCode)[[userInfo objectForKey:HydraNotifiationCodeKey] integerValue];
	suggestNumber = (NSNumber *)[userInfo objectForKey:HydraNotificationMigrationSuggestNumber];
	referenceNumber = (NSNumber *)[userInfo objectForKey:HydraNotificationMigrationReferenceNumber];
	NSString *logMessage;
	
	switch( code ) {
		case HydraNotificationCodeMigrationWillStart :
			logMessage = [NSString stringWithFormat:@"migration will start, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationWillInitialing :
			logMessage = [NSString stringWithFormat:@"migration will initialing, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationDidInitialing :
			logMessage = [NSString stringWithFormat:@"migration did start, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationFailedAtInitialing :
			logMessage = [NSString stringWithFormat:@"migration failed at initialing, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationWillStep :
			logMessage = [NSString stringWithFormat:@"migration will step, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationDidStep :
			logMessage = [NSString stringWithFormat:@"migration did step, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationFailedAtStep :
			logMessage = [NSString stringWithFormat:@"migration failed at step, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationDone :
			logMessage = [NSString stringWithFormat:@"migration done, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		case HydraNotificationCodeMigrationNothingToDo :
			logMessage = [NSString stringWithFormat:@"migration nothing to do, suggest[%@] reference[%@]", suggestNumber, referenceNumber];
			break;
		default :
			logMessage = @"unknown migration code";
			break;
	}
	
	[self appendLog:logMessage];
}

@end
