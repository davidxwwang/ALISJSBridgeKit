//
//  H5CommonPlugin.h
//  alisports.sportsman
//
//  Created by alisports on 2017/11/2.
//  Copyright © 2017年 alisports. All rights reserved.
//
#import <NebulaSDK/NebulaSDK.h>
#import <NebulaSDK/NBPluginBase.h>
#import <Foundation/Foundation.h>
#import "NebulaSDKManager.h"

// 通过- (void)addJSApi:(NSString *)name handler:(AlisJSApiHandlerBlock)handler;添加的JS方法
@interface H5CommonPlugin : NBPluginBase

@property(weak , nonatomic)NebulaSDKManager *manager;

@end
