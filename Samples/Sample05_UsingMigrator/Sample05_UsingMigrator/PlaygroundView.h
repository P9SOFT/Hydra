//
//  PlaygroundView.h
//  Sample05_UsingMigrator
//
//  Created by Tae Hyun, Na on 2015. 3. 11..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>

@interface PlaygroundView : UIView

@property (nonatomic, readonly) UITextView *logView;
@property (nonatomic, readonly) UITextField *suggestedMigrationNumberTextField;
@property (nonatomic, readonly) UIButton *resetButton;

@end
