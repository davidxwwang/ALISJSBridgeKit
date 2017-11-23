//
//  H5AlisPlugin.m
//  NebulaDemo
//
//  Created by Glance on 16/12/20.
//  Copyright © 2016年 Alipay. All rights reserved.
//
#import "NebulaSDKManager.h"
#import "H5AlisPlugin.h"
//#import "NebulaSDKManager.h"

//跳转
#define JSCall_MakeSegue                 (@"alisMakeSegue")

#define JSCall_ShareInfo                 (@"alisShareInfo")
// 唤起支付宝支付
#define JSCall_CallAlipay                (@"alisAlipay")
// 绑定身份证
#define JSCall_BindCitizenID             (@"alisBindCitizenID")
// 绑定手机
#define JSCall_BindMobile                (@"alisBindMobile")
//唤起登录
#define JSCall_Login                     (@"alisLogin")
//webview前进
#define JSCall_GoForward                 (@"alisGoForward")
//webview回退
#define JSCall_Goback                    (@"alisGoback")
//退出当前Webview
#define JSCall_CloseWebView              (@"alisCloseWebView")
//打电话
#define JSCall_MakePhoneCall             (@"alisMakePhoneCall")
//push 出一个新Webview
#define JSCall_OpenWebView               (@"alisOpenWebView")
//设置title
#define JSCall_SetWebviewTitle           (@"alisSetTitle")
//是否优先js后退
#define JSCall_JsNavi                   (@"alisJsNavi")
//当前页面分享
#define JSCall_Share                    (@"alisShare")

//是否有下拉刷新，默认有 。不调用情况，有
#define JSCall_CanReload                (@"alisCanReload")
//刷新当前页面
#define JSCall_Reload                   (@"alisReload")
//获取SSOToken
#define JSCall_GetSSOToken              (@"alisGetSsoToken")
//刷新SSOToken
#define JSCall_RefreshSSOToken          (@"alisRefreshSsoToken")

//获取城市信息
#define JSCall_GetCurrentLocation (@"alisGetCurrentLocation")

// 该插件已在Poseidon-Extra-Config.plist中注册
@implementation H5AlisPlugin

- (NSString *)dicToJson:(NSDictionary *)dic{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return json;
}

- (void)pluginDidLoad
{
    NSLog(@"%s is called",__func__);
    
    [[NSNotificationCenter defaultCenter]postNotificationName:AlisNebulaSDKPluginDidLoadNotification object:self];
    
    self.scope = kPSDScope_Scene;
    // 可监听的事件可参考 NBDefines.h
    [self.target addEventListener:kNBEvent_Scene_TitleView_Title_Click
                     withListener:self
                       useCapture:NO];
    [super pluginDidLoad];
}

- (void)addJSApis
{
    [super addJSApis];
    // 这种jsapi的注册是在plist中配置之外的另一种方式    
    PSDJsApi *jsApiAlisGetCurrentLocation = 
                        [PSDJsApi jsApi:JSCall_GetCurrentLocation
                                handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                                            
                                    ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                            
                                    NSDictionary *response = @{@"error":@"11",@"cityId":@"0",@"latitude":@"1",@"longitude":@"3"};
                                    responseCallbackBlock([self dicToJson:response]);
                                        }
                                    checkParams:NO
                                      isPrivate:NO
                                          scope:self.scope];
    [self registerJsApi2Target:jsApiAlisGetCurrentLocation];
    
    PSDJsApi *jsLogin = 
    [PSDJsApi jsApi:JSCall_Login
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                
                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                NSDictionary *response = @{@"error":@"11"};
                responseCallbackBlock([self dicToJson:response]);
            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsLogin];
    
    
    PSDJsApi *jsBindMobile = 
    [PSDJsApi jsApi:JSCall_BindMobile
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                
                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                NSDictionary *response = @{@"error":@"11"};
                responseCallbackBlock([self dicToJson:response]);
            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsBindMobile];
    
    PSDJsApi *jsBindCitizenID = 
    [PSDJsApi jsApi:JSCall_BindCitizenID
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                
                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                NSDictionary *response = @{@"error":@"11"};
                responseCallbackBlock([self dicToJson:response]);

            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsBindCitizenID];
    
    PSDJsApi *jsRefreshSSOToken = 
    [PSDJsApi jsApi:JSCall_RefreshSSOToken
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                
                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                
                NSDictionary *response = @{@"error":@"11",@"ssoToken":@"123"};
                responseCallbackBlock([self dicToJson:response]);
;
            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsRefreshSSOToken];
    
    PSDJsApi *jsGetSSOToken = 
    [PSDJsApi jsApi:JSCall_GetSSOToken
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                
                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                NSDictionary *response = @{@"error":@"11",@"ssoToken":@"123"};
                responseCallbackBlock([self dicToJson:response]);
            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsGetSSOToken];
    
    PSDJsApi *jsShare = 
    [PSDJsApi jsApi:JSCall_Share
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                
                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
                NSDictionary *response = @{@"error":@"11"};
                responseCallbackBlock([self dicToJson:response]);
            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsShare];
    
//    PSDJsApi *jsCallAlipay = 
//    [PSDJsApi jsApi:JSCall_CallAlipay
//            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
//                
//                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
//                NSDictionary *response = @{@"error":@"11"};
//                responseCallbackBlock([self dicToJson:response]);
//
//            }
//        checkParams:NO
//          isPrivate:NO
//              scope:self.scope];
//    [self registerJsApi2Target:jsCallAlipay];
    

    PSDJsApi *jsMakeSegue = 
    [PSDJsApi jsApi:JSCall_MakeSegue
            handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                AlisJSBridgeContext *_context = [[AlisJSBridgeContext alloc]init];
               // _context.JSApiName = context.
                [self handerJSCallBack:data context:_context responseCallbackBlock:responseCallbackBlock];
//                ([NebulaSDKManager sharedInstanse].apiHander)(@"ss",@"",nil);
//                responseCallbackBlock(@{@"result":@"makesegue"});
            }
        checkParams:NO
          isPrivate:NO
              scope:self.scope];
    [self registerJsApi2Target:jsMakeSegue];
    
//    
}
 
- (void)handleEvent:(PSDEvent *)event
{
    NSLog(@"%s is called",__func__);
    [super handleEvent:event];
    UIViewController *vc = event.context.currentViewController;
    UIWebView *webView = (UIWebView *)event.context.currentViewControllerProxy.psdContentView;
    NSString *eventType = event.eventType;
    NSLog(@"[NEBULADEMO]:有事件抛出，当前viewController %@, webView:%@, 事件名为 %@",vc, webView, eventType);
}

- (void)handerJSCallBack:(id)data context:(AlisJSBridgeContext *)context responseCallbackBlock:(AlisJSApiResponseCallbackBlock) responseCallbackBlock{
    if ([self.manager respondsToSelector:@selector(handerJSCallBack:context:responseCallbackBlock:)]) {
        [self.manager handerJSCallBack:data context:context responseCallbackBlock:responseCallbackBlock];
    }
}

@end
