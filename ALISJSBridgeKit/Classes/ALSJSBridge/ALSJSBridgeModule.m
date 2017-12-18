//
//  ALSJSBridgeModule.m
//  david_NebulaSDKDemo
//
//  Created by alisports on 2017/11/15.
//  Copyright © 2017年 alisports.sportsman. All rights reserved.
//
#import "AlisJSBridgeContext.h"
#import "ALSJSBridgeModule.h"
#import "ALSJSBridgeModuleManager.h"

@interface ALSJSBridgeModule()

@property(strong , nonatomic)NSMutableDictionary *JSMessagesHander;

@end

@implementation ALSJSBridgeModule

JS_EXPORT_MODULE();

- (id)init{
    if (self = [super init]) {
        _JSMessagesHander = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)moduleSourceFilePath{
    return nil;
}

- (void)attachToJSBridge:(ALSJSBridgeModuleManager *)moduleManager{  
    AlisJSApiHandlerBlock hander = ^(id data, AlisJSBridgeContext *context, AlisJSApiResponseCallbackBlock responseCallbackBlock){
        NSLog(@"%@ is called",context.JSApiName);
    };
    [self registerJSHandler:@"alisAlipay" handler:hander];
    
    AlisJSApiHandlerBlock hander2 = ^(id data, AlisJSBridgeContext *context, AlisJSApiResponseCallbackBlock responseCallbackBlock){
        NSLog(@"%@ is called",context.JSApiName);
    };
    [self registerJSHandler:@"aesSetTitle" handler:hander2];
}

- (void)registerJSHandler:(NSString *)name handler:(AlisJSApiHandlerBlock)handler{
    _JSMessagesHander[name] = [handler copy];
}

- (NSDictionary *)messagesHander{
    return _JSMessagesHander;
}

@end
