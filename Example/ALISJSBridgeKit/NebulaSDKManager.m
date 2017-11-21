//
//  NebulaSDKManager.m
//  alisports.sportsman
//
//  Created by alisports on 2017/10/31.
//  Copyright © 2017年 alisports. All rights reserved.
//  name hander必须有
//
#import <UIKit/UIKit.h>
#import "NebulaSDKManager.h"
#import "H5WebViewController.h"
#import "H5AlisPlugin.h"
#import "H5CommonPlugin.h"

NSString *const AlisNebulaSDKPluginJSCallBackNotification = @"AlisNebulaSDKPluginJSCallBackNotification";

@interface NebulaSDKManager ()

/**
 指向由Nebula框架生成的VC
 */
@property(weak ,   nonatomic)UIViewController *h5ViewController;
@property(strong , nonatomic)NSMutableDictionary *addedExtraJSHanderDic;
@property(strong , nonatomic)NSString *currentUrl;

@end

@implementation NebulaSDKManager {
}

@synthesize apiHander;

JSSDKPLUGIN_EXPORT_MODULE();

+ (NebulaSDKManager *)sharedInstanse{
    static NebulaSDKManager *shared = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[NebulaSDKManager alloc] init];
       
    });
    return shared;
}

- (id)init{
    if(self = [super init]){
        self.addedExtraJSHanderDic = [NSMutableDictionary dictionary];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidLoad:) name:AlisNebulaSDKPluginJSCallBackNotification object:nil];
    }
    return self;
}

- (void)pluginDidLoad:(NSNotification *)notifacation{
    id yy = notifacation.object;
    if ([yy isKindOfClass:[H5AlisPlugin class]]) {
        ((H5AlisPlugin *)yy).manager = self;
    }
    
    if ([yy isKindOfClass:[H5CommonPlugin class]]) {
        ((H5CommonPlugin *)yy).manager = self;
    }
}

#pragma mark ---delegate
- (UIViewController *)configJSBridgePluginWithUrl:(NSString *)url{
    [self startNBService];
    
    _currentUrl = url;
   
    NSMutableDictionary *mCreateParams = [NSMutableDictionary dictionary];
    NSString *path2 = _currentUrl;
    [mCreateParams setValue:path2 forKey:@"url"];
    UIViewController *vc = (UIViewController *)[NBServiceGet() createNBViewController:mCreateParams];
    self.h5ViewController = vc;
    vc.view.backgroundColor = [UIColor whiteColor];
    
    return vc;
}

- (void)configJSBridgeWithExtraPluginsFilePath:(NSString *)extraPluginsFilePath{
    [NBServiceConfigurationGet() setExtraPluginsFilePath:extraPluginsFilePath];
}

/**
 配置开启服务
 */
- (void)startNBService{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *extraPluginsFilePath = [[NSBundle mainBundle].bundlePath stringByAppendingFormat:@"/%@/%@", @"DemoPlugins.bundle", @"Poseidon-Extra-Config.plist"];
        [NBServiceConfigurationGet() setExtraPluginsFilePath:extraPluginsFilePath];
        
        [NBServiceConfigurationGet() setViewControllerClass:[H5WebViewController class]];
        [NBServiceConfigurationGet() setContentViewClass:[UIWebView class]];
        NAMServiceGet();
        [NBServiceGet() start];
        
    });
}

- (NSDictionary *)addedExtraJSHandersDic{
    return [_addedExtraJSHanderDic copy];
}

- (NSDictionary *)JSHandersDicForClassStr:(NSString *)classString{
    return [[_addedExtraJSHanderDic copy] objectForKey:@"name"];
}

- (void)registerJSApi:(NSDictionary *)JSHander{
    if (JSHander) {
        [self.addedExtraJSHanderDic addEntriesFromDictionary:JSHander];
    }
}

- (void)addJSApi:(NSString *)name handler:(AlisJSApiHandlerBlock)handler{
    if (name == nil) return;
    [self.addedExtraJSHanderDic setObject:handler forKey:name];
}

- (void)addJSContent:(NSString *)moduleSourceFile{
     NSString *source = [[NSString alloc] initWithContentsOfFile:moduleSourceFile encoding:NSUTF8StringEncoding error:NULL];
}

- (void)addJSApis:(NSArray *)namesArray handler:(AlisJSApiHandlerBlock)handler{
    if (namesArray == nil) return;
    [namesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.addedExtraJSHanderDic
         setObject:obj forKey:namesArray[idx]];
    }];
}

//native --> h5
- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(void (^)(id))callback{
    if (handlerName == nil) return;
    
    [self.h5ViewController callHandler:handlerName data:data responseCallback:^(NSDictionary *responseData){
        if (callback) {
            callback(responseData);
        }
    }];
}

- (void)handerJSCallBack:(id)data context:(AlisJSBridgeContext *)context responseCallbackBlock:(AlisJSApiResponseCallbackBlock)responseCallbackBlock{
    self.apiHander(data, context, responseCallbackBlock);
}

- (UIViewController *)H5ViewControllerWithUrl:(NSString *)urlString{   
    return [self configJSBridgePluginWithUrl:urlString];
}

@end



