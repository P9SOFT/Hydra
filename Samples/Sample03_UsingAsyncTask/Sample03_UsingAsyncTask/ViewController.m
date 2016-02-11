//
//  ViewController.m
//  Sample03_UsingAsyncTask
//
//  Created by Tae Hyun Na on 2015. 2. 20.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "ViewController.h"
#import "SampleManager.h"

@interface ViewController (ViewControllerPrivate)

- (void)touchUpInsideDoButton:(id)sender;
- (void)sampleManagerReport:(NSNotification *)notification;

@end

@implementation ViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	_playgroundView = [[PlaygroundView alloc] init];
	_playgroundView.frame = self.view.bounds;
	[self.view addSubview:_playgroundView];
	
	[_playgroundView.doButton addTarget:self action:@selector(touchUpInsideDoButton:) forControlEvents:UIControlEventTouchUpInside];
	// observe manager notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sampleManagerReport:) name:SampleManagerNotification object:nil];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)touchUpInsideDoButton:(id)sender
{
	// make url string for sample
	NSString *urlString = @"http://www.p9soft.com/images/sample.jpg";
	// call manager method
	UIImage *image = [[SampleManager defaultManager] loadImageFromUrlString:urlString];
	if( image != nil ) {
		_playgroundView.imageView.image = image;
	} else {
		_playgroundView.doButton.enabled = NO;
        [_playgroundView.activityIndicator startAnimating];
	}
}

- (void)sampleManagerReport:(NSNotification *)notification
{
	NSDictionary			*userInfo;
	SampleManagerOperation	operation;
	UIImage					*image;
	
	// get result of executor and update UI if need
	
	userInfo = [notification userInfo];
	
	operation = (SampleManagerOperation)[[userInfo objectForKey:SampleManagerNotifyParameterKeyOperation] integerValue];
	
	switch( operation ) {
		case SampleManagerOperationLoadImage :
			if( (image = [userInfo objectForKey:SampleManagerNotifyParameterKeyOperandImage]) != nil ) {
				_playgroundView.imageView.image = image;
			}
			_playgroundView.doButton.enabled = YES;
            [_playgroundView.activityIndicator stopAnimating];
			break;
		default:
			break;
	}
}

@end
