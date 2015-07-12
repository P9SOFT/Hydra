//
//  PlaygroundView.m
//  Sample05_UsingMigrator
//
//  Created by Tae Hyun, Na on 2015. 3. 11..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "PlaygroundView.h"

@implementation PlaygroundView

@synthesize logView = _logView;
@synthesize suggestedMigrationNumberTextField = _suggestedMigrationNumberTextField;
@synthesize resetButton = _resetButton;

- (id)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) != nil ) {
		
		self.backgroundColor = [UIColor lightGrayColor];
		
		if( (_logView = [[UITextView alloc] init]) == nil ) {
			return nil;
		}
		_logView.backgroundColor = [UIColor whiteColor];
		_logView.editable = NO;
		
		if( (_suggestedMigrationNumberTextField = [[UITextField alloc] init]) == nil ) {
			return nil;
		}
		_suggestedMigrationNumberTextField.backgroundColor = [UIColor whiteColor];
		_suggestedMigrationNumberTextField.enabled = NO;
		
		if( (_resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect]) == nil ) {
			return nil;
		}
		_resetButton.backgroundColor = [UIColor whiteColor];
		_resetButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		[_resetButton setTitle:NSLocalizedString(@"Reset", @"") forState:UIControlStateNormal];
		
		[self addSubview:_logView];
		[self addSubview:_suggestedMigrationNumberTextField];
		[self addSubview:_resetButton];
		
	}
	
	return self;
}

- (void)layoutSubviews
{
	CGRect		frame;
	
	frame.size.width = self.bounds.size.width - 20.0f;
	frame.size.height = 200.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = 30.0f;
	
	_logView.frame = frame;
	
	frame.size.width = 100.0f;
	frame.size.height = 30.0f;
	frame.origin.x = 10.0f;
	frame.origin.y = _logView.frame.origin.y + _logView.frame.size.height + 10.0f;
	
	_suggestedMigrationNumberTextField.frame = frame;
	
	frame.size.width = 100.0f;
	frame.size.height = 30.0f;
	frame.origin.x = self.bounds.size.width - 10.0f - frame.size.width;
	frame.origin.y = _logView.frame.origin.y + _logView.frame.size.height + 10.0f;
	
	_resetButton.frame = frame;
}

@end
