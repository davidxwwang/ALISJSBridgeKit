//
//  ALSJSBridgeModuleManager.m
//  david_NebulaSDKDemo
//
//  Created by alisports on 2017/11/15.
//  Copyright © 2017年 alisports.sportsman. All rights reserved.
//

#import "AlisJSBridgeContext.h"
#import "ALSJSBridgeModuleManager.h"

//JS加载模块
static NSMutableArray<Class> *JSModuleClasses;

void JSRegisterModule(Class moduleClass){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSModuleClasses = [NSMutableArray array];
    });
    
    if (![moduleClass conformsToProtocol:@protocol(ALSJSBridgeModule)]) {
        NSLog(@"%@ is not conform to \"ALSJSBridgeModule\" protocol",moduleClass);
        return;
    }
    [JSModuleClasses addObject:moduleClass];
}

//JS三方库加载模块
static NSMutableArray<Class> *JSSDKPluginClasses;

void JSSDKPluginRegisterModule(Class JSSDKPluginClass){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSSDKPluginClasses = [NSMutableArray array];
    });
    
    if (![JSSDKPluginClass conformsToProtocol:@protocol(ALISBridgePluginProtocol)]) {
        NSLog(@"%@ is not conform to \"ALISBridgePluginProtocol\" protocol",JSSDKPluginClass);
        return;
    }
    [JSSDKPluginClasses addObject:JSSDKPluginClass];
}


@interface ALSJSBridgeModuleManager()
/**
 JS模块数组
 */
@property(strong , nonatomic)NSMutableArray *JSModules;
// JS三方库
@property(strong , nonatomic)NSMutableArray *JSSDKPlugins;

@end

@implementation ALSJSBridgeModuleManager

static ALSJSBridgeModuleManager *_JSCurrentBridgeInstance = nil;

+ (instancetype)sharedBridge {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _JSCurrentBridgeInstance = [[ALSJSBridgeModuleManager alloc] init];
    });
    return _JSCurrentBridgeInstance;
}

- (instancetype)init{
    if(self = [super init]){ 
        _JSModules = [NSMutableArray array];
        _JSSDKPlugins = [NSMutableArray array];
    }
    return self;
}

- (void)addModule:(id<ALSJSBridgeModule>)module{
    [_JSModules addObject:module];
}

- (void)removeModule:(id<ALSJSBridgeModule>)module{
    [_JSModules removeObject:module];
}

- (id<ALSJSBridgeModule>)moduleForName:(NSString *)moduleName{
    for (id<ALSJSBridgeModule> module in self.JSModules) {
        NSString *s = NSStringFromClass([module class]);
        if ([s isEqualToString:moduleName]) {
            return module;
        }
    }
    return nil;
}

- (void)attachToBridge{
    //首先加载三方SDK的plugin
    [self launchJSSDKPlugins];
    
    [_JSModules removeAllObjects];
    for (Class c in JSModuleClasses) {
        id<ALSJSBridgeModule> module = [c new];
        [_JSModules addObject:module];
    }
    
    //todo
    for (id<ALSJSBridgeModule>module in _JSModules) {
        //每个JS模块加载JS
        [module attachToJSBridge:self];
        //加载JS
        [self registerHanderWithModule:module];
    }
}

- (void)launchJSSDKPlugins{
    [_JSSDKPlugins removeAllObjects];
    __weak typeof (self) weakSelf = self;
    for (Class c in JSSDKPluginClasses) {
        id<ALISBridgePluginProtocol> plugin = [c new];
        plugin.apiHander = ^(id data, AlisJSBridgeContext *context, AlisJSApiResponseCallbackBlock responseCallbackBlock) {             
            [weakSelf handerJSCallBack:data context:context  responseCallbackBlock:responseCallbackBlock];
        };
        [_JSSDKPlugins addObject:plugin];
    }
}

- (id<ALISBridgePluginProtocol>)allPlugins{
    return [_JSSDKPlugins copy];
}

- (id<ALISBridgePluginProtocol>)pluginWithName:(NSString *)pluginName{
    __block id<ALISBridgePluginProtocol> plugin = nil;
    [_JSSDKPlugins enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *n = NSStringFromClass([(id<ALISBridgePluginProtocol>)obj class]);
        if ([n isEqualToString:pluginName]) {
            plugin = (id<ALISBridgePluginProtocol>)obj;
            *stop = YES;
        }
    }];
    return plugin;
}

- (void)registerHanderWithModule:(id<ALSJSBridgeModule>)module{
    NSDictionary *JSMessageHander = [module messagesHander];
    NSString *moduleSourceFilePath = [module moduleSourceFilePath];
    //向优先级最高的第三方SDK注册JSplugin
    id<ALISBridgePluginProtocol> highestPriorityPlugin = [self highestPriorityPlugin];
    if (highestPriorityPlugin) {
        if ([highestPriorityPlugin respondsToSelector:@selector(registerJSApi:)]) {
            [highestPriorityPlugin registerJSApi:JSMessageHander];
        }
        //加载JS文件
        if ([highestPriorityPlugin respondsToSelector:@selector(addJSContent:)]) {
            [highestPriorityPlugin addJSContent:moduleSourceFilePath];
        }
    }else{
        NSLog(@"没有可用的plugin，注意检查");
    }
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(void (^)(id))callback{
    id<ALISBridgePluginProtocol> highestPriorityPlugin = [self highestPriorityPlugin];
    if (highestPriorityPlugin) {
        if ([highestPriorityPlugin respondsToSelector:@selector(callHandler:data:responseCallback:)]) {
            [highestPriorityPlugin callHandler:handlerName data:data responseCallback:callback];
        }
    }else{
        NSLog(@"没有可用的plugin，注意检查");
    }
}

/**
 处理从webview回调的数据
 */
- (void)handerJSCallBack:(id)data context:(AlisJSBridgeContext *)context responseCallbackBlock:(AlisJSApiResponseCallbackBlock) responseCallbackBlock{
    
    for (id<ALSJSBridgeModule>module in _JSModules) {
        NSDictionary *messagesHanderDic = [module messagesHander];
        [messagesHanderDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isEqualToString:context.JSApiName]) {
                AlisJSApiHandlerBlock handler = (AlisJSApiHandlerBlock)obj;
                handler(data , context , responseCallbackBlock);
            }
        }];
    }    
}

- (void)reset{
}

- (UIViewController *)H5ViewControllerWithUrl:(NSString *)urlString{
    //向优先级最高的第三方SDK请求
    id<ALISBridgePluginProtocol> highestPriorityPlugin = [self highestPriorityPlugin];
    for (id<ALSJSBridgeModule>module in _JSModules) {
        //每个JS模块加载JS
        [module attachToJSBridge:self];
        //加载JS
        [self registerHanderWithModule:module];
    }
    if ([highestPriorityPlugin respondsToSelector:@selector(H5ViewControllerWithUrl:)]) {
        return [highestPriorityPlugin H5ViewControllerWithUrl:urlString];
    }
    return nil;
}

/**
 最高优先级的plugin
 */
- (id<ALISBridgePluginProtocol>)highestPriorityPlugin{
    id<ALISBridgePluginProtocol> highestPriorityPlugin = nil;
    NSInteger highestPriority = -1000;
    for (id<ALISBridgePluginProtocol> plugin in _JSSDKPlugins) {
        ALSJSPluginPriority tempPriority = plugin.priority;
        if (tempPriority) {
            if(tempPriority > highestPriority){
                highestPriority = tempPriority;
                highestPriorityPlugin = plugin;
            }
        }
    }
    return highestPriorityPlugin;
}

@end


