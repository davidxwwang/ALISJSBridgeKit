//
//  AEHybridEngineManager.m
//  ALISJSBridgeKit_Example
//
//  Created by alisports on 2017/11/27.
//  Copyright © 2017年 xwwang_0102@qq.com. All rights reserved.
//
#import "AlisJSBridgeContext.h"
#import "AEHybridEngineManager.h"
#import "AEHybridEngineViewController.h"

@interface AEHybridEngineManager()

@property(strong , nonatomic)AEHybridEngineViewController *viewController;
@property(strong , nonatomic)NSMutableDictionary *addedExtraJSHanderDic;

@end

@implementation AEHybridEngineManager
#if __has_include(<ALISJSBridgeKit/ALISJSBridgeKit.h>)
    JSSDKPLUGIN_EXPORT_MODULE();
#endif

- (instancetype)init{
    if (self = [super init]) {
        _addedExtraJSHanderDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (AEHybridEngineViewController *)viewController{
    if (_viewController == nil) {
        _viewController = [[AEHybridEngineViewController alloc]init];
        _viewController.manager = self;
       
    }
    return _viewController;
}

- (void)registerJSApi:(NSDictionary *)JSHander{
    if (_addedExtraJSHanderDic) {
        [_addedExtraJSHanderDic addEntriesFromDictionary:JSHander];
    }
    [self addCustomJS];
}

- (void)addCustomJS{
    NSMutableArray *JSApiArray = [NSMutableArray array];
    [_addedExtraJSHanderDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {

        AEJSHandlerBlockContext *blockJSContext = [AEJSHandlerBlockContext contextWithAliasName:key jsCallback:^(AEJSHandlerBlockContext * _Nonnull context) {
            AlisJSApiHandlerBlock hander = (AlisJSApiHandlerBlock)obj;
            AlisJSBridgeContext *_context = [[AlisJSBridgeContext alloc]init];
            _context.JSApiName = context.aliasName;
            _context.orignalData = context.args;
            
            AlisJSApiResponseCallbackBlock responseCallbackBlock = ^(id responseData){
//context.JSCallback(@"");
            };
            hander(context.args,_context,responseCallbackBlock);
        }];
        
        [JSApiArray addObject:blockJSContext];
    }];
    [self.viewController addJSContexts:[NSSet setWithArray:JSApiArray]];
}

- (UIViewController *)H5ViewControllerWithUrl:(NSString *)urlString{
    [self.viewController configJSBridgePluginWithUrl:urlString];
    return self.viewController;
}

//native --> h5
- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(void (^)(id))callback{
    [self.viewController callHandler:handlerName data:data responseCallback:callback];
    

}


@end
