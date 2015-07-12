//
//  ViewController.m
//  Sample04_UsingTrackingResultSet
//
//  Created by Tae Hyun, Na on 2015. 3. 10..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "ViewController.h"
#import "SampleManager.h"

@interface ViewController (ViewControllerPrivate)

- (void)appendLog:(NSString *)logString;
- (void)touchUpInsideBooButton:(id)sender;
- (void)touchUpInsideFooButton:(id)sender;
- (void)sampleManagerReport:(NSNotification *)notification;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	_playgroundView = [[PlaygroundView alloc] init];
	_playgroundView.frame = self.view.bounds;
	[self.view addSubview:_playgroundView];
	
	[_playgroundView.booButton addTarget:self action:@selector(touchUpInsideBooButton:) forControlEvents:UIControlEventTouchUpInside];
	[_playgroundView.fooButton addTarget:self action:@selector(touchUpInsideFooButton:) forControlEvents:UIControlEventTouchUpInside];
	// observe manager notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sampleManagerReport:) name:SampleManagerNotification object:nil];
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

- (void)touchUpInsideBooButton:(id)sender
{
	[[SampleManager defaultManager] boo];
}

- (void)touchUpInsideFooButton:(id)sender
{
	[[SampleManager defaultManager] foo];
}

- (void)sampleManagerReport:(NSNotification *)notification
{
	NSDictionary			*userInfo;
	SampleManagerOperation	operation;
	
	// get result of executor and update UI if need
	
	userInfo = [notification userInfo];
	
	operation = (SampleManagerOperation)[[userInfo objectForKey:SampleManagerNotifyParameterKeyOperation] integerValue];
	
	switch( operation ) {
		case SampleManagerOperationBoo :
			[self appendLog:@"boo"];
			break;
		case SampleManagerOperationFoo :
			[self appendLog:@"foo"];
			break;
		case SampleManagerOperationBooAndFooAllUpdated :
			[self appendLog:@"boo and foo all updated"];
			break;
		default:
			break;
	}
}

@end
