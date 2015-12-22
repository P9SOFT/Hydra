//
//  ViewController.m
//  Sample01_UsingExecutor
//
//  Created by Tae Hyun, Na on 2015. 2. 17..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import <Hydra/Hydra.h>
#import "CommonWorker.h"
#import "SampleExecutor.h"
#import "ViewController.h"

@interface ViewController (ViewControllerPrivate)

- (void)touchUpInsideDoButton:(id)sender;
- (void)commonWorkerNotification:(NSNotification *)notification;

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
	// observe worker notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commonWorkerNotification:) name:CommonWorkerName object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
	[_playgroundView.inputNumberTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)touchUpInsideDoButton:(id)sender
{
	NSUInteger inputNumberValue = (NSUInteger)[_playgroundView.inputNumberTextField.text integerValue];
	
	// make query and push to hydra
	HYQuery *query;
	if( (query = [HYQuery queryWithWorkerName:CommonWorkerName executerName:SampleExecutorName]) != nil ) {
		_playgroundView.doButton.enabled = NO;
		[query setParameter:[NSNumber numberWithUnsignedInteger:inputNumberValue] forKey:SampleExecutorParameterKeyInputNumber];
		[[Hydra defaultHydra] pushQuery:query];
	}
}

- (void)commonWorkerNotification:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	
	// get result of executor and update UI
	HYResult *result = [userInfo objectForKey:SampleExecutorName];
	if( result != nil ) {
		NSNumber *outputNumber = [result parameterForKey:SampleExecutorParameterKeyOutputNumber];
		if( outputNumber != nil ) {
			_playgroundView.outputNumberTextField.text = [outputNumber stringValue];
			NSNumber *inputNumber = [result parameterForKey:SampleExecutorParameterKeyInputNumber];
			if( inputNumber != nil ) {
				_playgroundView.inputNumberTextField.text = [inputNumber stringValue];
			}
		} else {
			NSString *errorMessage = [result parameterForKey:SampleExecutorParameterKeyErrorMessage];
			if( [errorMessage length] > 0 ) {
				_playgroundView.outputNumberTextField.text = errorMessage;
			}
		}
		_playgroundView.doButton.enabled = YES;
	}
}

@end
