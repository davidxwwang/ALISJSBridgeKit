//
//  ALSJSBridgeModuleProtocol.h
//  david_NebulaSDKDemo
//
//  Created by alisports on 2017/11/15.
//  Copyright © 2017年 alisports.sportsman. All rights reserved.
//

#ifndef ALSJSBridgeModuleProtocol_h
#define ALSJSBridgeModuleProtocol_h

#import "ALSJSDefine.h"

@class ALSJSBridgeModuleManager;
@protocol ALSJSBridgeModule<NSObject>

#define JS_EXPORT_MODULE(js_name) \
JS_EXTERN void JSRegisterModule(Class); \
+ (NSString *)moduleName { return @#js_name; } \
+ (void)load { JSRegisterModule(self); }
/**
 JSModule名称
 */
+ (NSString *)moduleName;

/**
 JSModule中JS文件路径
 */
- (NSString *)moduleSourceFilePath;

- (void)attachToJSBridge:(ALSJSBridgeModuleManager *)moduleManager;

- (void)registerJSHandler:(NSString *)name
                  handler:(AlisJSApiHandlerBlock)handler;
/**
 module中注册的hander
 */
- (NSDictionary *)messagesHander;

@end

#endif /* JSBridgeModuleProtocol_h */
