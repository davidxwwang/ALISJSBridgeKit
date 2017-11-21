//
//  PSDNavigationEvent.h
//  Poseidon
//
//  Created by chenwenhong on 14-8-11.
//  Copyright (c) 2014年 Alipay. All rights reserved.
//

#import "PSDEvent.h"
#import <UIKit/UIKit.h>

@interface PSDNavigationEvent : PSDEvent

@property(nonatomic, strong) NSURLRequest *request;
@property(nonatomic, assign) UIWebViewNavigationType navigationType;
@property(nonatomic, strong) NSError *error;

+ (instancetype)allEvent:(NSURLRequest *)request;

+ (instancetype)startEvent:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

+ (instancetype)completeEvent:(NSURLRequest *)request;

+ (instancetype)errorEvent:(NSURLRequest *)request error:(NSError *)error;

@end
