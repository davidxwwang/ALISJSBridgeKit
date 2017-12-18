//
//  H5JsApi4DemoTest.m
//  NebulaDemo
//
//  Created by Glance on 16/12/20.
//  Copyright © 2016年 Alipay. All rights reserved.
//
#import "NebulaSDKManager.h"
#import "H5JsApi4DemoTest.h"
// 该JSApi已在Poseidon-Extra-Config.plist中注册
#ifdef ALS_HAS_NebulaSDK 

@implementation H5JsApi4DemoTest

- (void)handler:(NSDictionary *)data
        context:(PSDContext *)context
       callback:(PSDJsApiResponseCallbackBlock)callback
{
    [super handler:data context:context callback:callback];
    UIViewController *vc = context.currentViewController;
    UIWebView *webView = (UIWebView *)context.currentViewControllerProxy.psdContentView;
    NSLog(@"[NEBULADEMO]:JSAPI调用，当前viewController %@, webView:%@, jsApi实例为 %@",vc, webView, self);

    if (!data) {
        ErrorCallback(callback, e_inavlid_params);
        return;
    }
    
    AlisJSApiHandlerBlock handerBlock = [NebulaSDKManager sharedInstanse].apiHander;
    handerBlock(data , context , callback);
    
}

@end

#endif
