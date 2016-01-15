//
//  HYDefine.h
//  Hydra
//
//  Created by Tae Hyun Na on 2012. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>


#ifdef DEBUG

#define		__FILENAME__			(strrchr(__FILE__, '/') + 1)

#define		HYLOG( s, ... )			NSLog( @"%@", [NSString stringWithFormat: (s), ##__VA_ARGS__] )
#define		HYTRACE( s, ... )		NSLog( @"%s:%d: %@", __FILENAME__, __LINE__, [NSString stringWithFormat: (s), ##__VA_ARGS__] )
#define		HYTRACE_BLOCK( s )		s

#else

#define		HYLOG( s, ... )
#define		HYTRACE( s, ... )
#define		HYTRACE_BLOCK( s )

#endif
