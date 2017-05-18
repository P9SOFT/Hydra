//
//  PlaygroundView.m
//  Sample01_UsingExecutor
//
//  Created by Tae Hyun Na on 2015. 2. 17.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "PlaygroundView.h"

@implementation PlaygroundView

@synthesize inputNumberTextField = _inputNumberTextField;
@synthesize outputNumberTextField = _outputNumberTextField;
@synthesize doButton = _doButton;

- (instancetype)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) != nil ) {
		
		self.backgroundColor = [UIColor lightGrayColor];
		
		if( (_inputNumberTextField = [[UITextField alloc] init]) == nil ) {
			return nil;
		}
		_inputNumberTextField.backgroundColor = [UIColor whiteColor];
		_inputNumberTextField.placeholder = @"Input Number(0~32)";
		_inputNumberTextField.keyboardType = UIKeyboardTypeDecimalPad;
		
		if( (_outputNumberTextField = [[UITextField alloc] init]) == nil ) {
			return nil;
		}
		_outputNumberTextField.backgroundColor = [UIColor whiteColor];
		_outputNumberTextField.placeholder = @"Output Number";
		_outputNumberTextField.userInteractionEnabled = NO;
		
		if( (_doButton = [UIButton buttonWithType:UIButtonTypeRoundedRect]) == nil ) {
			return nil;
		}
		_doButton.backgroundColor = [UIColor whiteColor];
		_doButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		[_doButton setTitle:NSLocalizedString(@"Factorial", @"") forState:UIControlStateNormal];
		
		[self addSubview:_inputNumberTextField];
		[self addSubview:_outputNumberTextField];
		[self addSubview:_doButton];
		
	}
	
	return self;
}

- (void)layoutSubviews
{
	CGRect		frame;
	
	frame.size.width = 300.0f;
	frame.size.height = 30.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = 100.0f;
	
	_inputNumberTextField.frame = frame;
	
	frame.origin.y = (_inputNumberTextField.frame.origin.y+_inputNumberTextField.frame.size.height+20.0f);
	
	_outputNumberTextField.frame = frame;
	
	frame.size.width = 100.0f;
	frame.size.height = 30.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = (_outputNumberTextField.frame.origin.y+_outputNumberTextField.frame.size.height+20.0f);
	
	_doButton.frame = frame;
}

@end
