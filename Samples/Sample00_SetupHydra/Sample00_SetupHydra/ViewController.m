//
//  ViewController.m
//  Sample00_SetupHydra
//
//  Created by Tae Hyun, Na on 2015. 2. 17..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	_playgroundView = [[PlaygroundView alloc] init];
	_playgroundView.frame = self.view.bounds;
	[self.view addSubview:_playgroundView];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
