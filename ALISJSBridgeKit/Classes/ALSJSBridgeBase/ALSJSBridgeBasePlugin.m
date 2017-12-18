//
//  ALSJSBridgeBasePlugin.m
//  ALISJSBridgeKit
//
//  Created by alisports on 2017/11/23.
//

#import "ALSJSBridgeBasePlugin.h"

NSString *const AlisNebulaSDKPluginDidLoadNotification = @"AlisNebulaSDKPluginDidLoadNotification";

@implementation ALSJSBridgeBasePlugin

@synthesize apiHander,priority;

- (instancetype)init{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidLoad:) name:AlisNebulaSDKPluginDidLoadNotification object:nil];
        self.priority = KALSJSPluginPriorityLow;
        
    }
    return self;
}

- (void)pluginDidLoad:(NSNotification *)notifacation{
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark --- delegate ---

- (UIViewController *)H5ViewControllerWithUrl:(NSString *)urlString { 
    return nil;
}

- (void)addJSApi:(NSString *)name handler:(AlisJSApiHandlerBlock)handler { 
    
}

- (void)addJSApis:(NSArray *)namesArray handler:(AlisJSApiHandlerBlock)handler { 
    
}

- (void)addJSContent:(NSString *)moduleSourceFile { 
    
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(void (^)(id))callback { 
    
}

- (UIViewController *)configJSBridgePluginWithUrl:(NSString *)url { 
    return nil;
}

- (void)configJSBridgeWithExtraPluginsFilePath:(NSString *)extraPluginsFilePath { 
    
}

- (void)handerJSCallBack:(id)data context:(AlisJSBridgeContext *)context responseCallbackBlock:(AlisJSApiResponseCallbackBlock)responseCallbackBlock { 
    
}

- (void)registerJSApi:(NSDictionary *)JSHander { 
    
}

@end
