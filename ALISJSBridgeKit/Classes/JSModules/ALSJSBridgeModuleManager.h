//
//  ALSJSBridgeModuleManager.h
//  david_NebulaSDKDemo
//
//  Created by alisports on 2017/11/15.
//  Copyright © 2017年 alisports.sportsman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSJSBridgeModule.h"

@interface AlisJSBridgeContext : NSObject
//原始数据
@property(strong , nonatomic) id orignalData;
@property(strong , nonatomic) id context;
@property(strong , nonatomic) NSString *JSApiName;

@end

@interface ALSJSBridgeModuleManager : NSObject

+ (instancetype)sharedBridge;

- (id<ALSJSBridgeModule>)moduleForName:(NSString *)moduleName;

- (id<ALISBridgePluginProtocol>)allPlugins;
- (id<ALISBridgePluginProtocol>)pluginWithName:(NSString *)pluginName;

/**
 加载JSModule
 */
- (void)attachToBridge;

/**
 加载三方JS的SDK，这个是自动化完成的
 */
- (void)launchJSSDKPlugins;


- (UIViewController *)H5ViewControllerWithUrl:(NSString *)urlString;

@end
