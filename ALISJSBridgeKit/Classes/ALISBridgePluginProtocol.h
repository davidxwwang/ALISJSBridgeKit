//
//  AlisJSBridgeDelegate.h
//  alisports.sportsman
//
//  Created by alisports on 2017/10/31.
//  Copyright © 2017年 alisports. All rights reserved.
//

#ifndef ALSJSBridgeModuleManager_h
#define ALSJSBridgeModuleManager_h

#import <UIKit/UIKit.h>
#import "ALSJSDefine.h"

@class AlisJSBridgeContext;
typedef void (^AlisJSApiResponseCallbackBlock)(id responseData);
typedef void (^AlisJSApiHandlerBlock)(id data, AlisJSBridgeContext *context, AlisJSApiResponseCallbackBlock responseCallbackBlock);

@protocol  ALISBridgePluginProtocol<NSObject>

#define JSSDKPLUGIN_EXPORT_MODULE(js_name) \
JS_EXTERN void JSSDKPluginRegisterModule(Class); \
+ (NSString *)moduleName { return @#js_name; } \
+ (void)load { JSSDKPluginRegisterModule(self); }
/**
 使用extra的plugin配置

 @param extraPluginsFilePath extraPlugins路径
 */
- (void)configJSBridgeWithExtraPluginsFilePath:(NSString *)extraPluginsFilePath;

- (UIViewController *)configJSBridgePluginWithUrl:(NSString *)url;

/**
 添加JS方法
 H5调用Native
 @param name JS方法名
 @param handler 从H5回调回来的Block
 */
- (void)addJSApi:(NSString *)name
         handler:(AlisJSApiHandlerBlock)handler;
                        // scope:(NSString *)scope;

- (void)addJSApis:(NSArray *)namesArray
         handler:(AlisJSApiHandlerBlock)handler;

/**
 注册JS
 @param JSHander key为JS名称，value为hander
 */
- (void)registerJSApi:(NSDictionary *)JSHander;

- (void)addJSContent:(NSString *)moduleSourceFile;


/**
 Native通过JS调用H5

 @param handlerName 定义好的JS名称
 @param data 传输的数据
 @param callback 回调Block
 */
- (void)callHandler:(NSString *)handlerName
               data:(id)data
   responseCallback:(void(^)(id responseData))callback;

/**
 处理来自H5的JS回调

 @param data JS数据
 @param context JS环境
 @param responseCallbackBlock JS回调
 */
- (void)handerJSCallBack:(id)data context:(AlisJSBridgeContext *)context responseCallbackBlock:(AlisJSApiResponseCallbackBlock) responseCallbackBlock;

//处理的hander
@property(strong ,nonatomic)AlisJSApiHandlerBlock apiHander;

- (UIViewController *)H5ViewControllerWithUrl:(NSString *)urlString;

@end

#endif /* AlisJSBridgeDelegate_h */
