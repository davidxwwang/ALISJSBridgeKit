//
//  AEHybridEngineViewController.m
//  PROJECT
//
//  Created by PROJECT_OWNER on TODAYS_DATE.
//  Copyright (c) TODAYS_YEAR PROJECT_OWNER. All rights reserved.
//

#import "AEHybridEngineViewController.h"
#import <objc/runtime.h>

@implementation AESJSCallBack

+ (instancetype)callBackWithRawData:(NSDictionary *)data {
    if (!data || ![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    AESJSCallBack *callBack = [[AESJSCallBack alloc] init];
    callBack.succeedCallBack = [data objectForKey:@"success_callback"];
    callBack.failureCallBack = [data objectForKey:@"fail_callback"];
    
    return callBack;
}

@end


@interface AEHybridEngineViewController ()

@property (strong, nonatomic)  AEWebViewContainer *webView;

@property (nonatomic, strong) AEJavaScriptHandler *handler;

@property (nonatomic, strong) NSArray *tableArray;

@property (nonatomic, strong) NSSet<AEJSHandlerContext *> *contexts;

@property (nonatomic, copy)NSString *currentUrl;

@end

@implementation AEHybridEngineViewController

- (BOOL)addJSContexts:(NSSet<AEJSHandlerContext *> *)contexts{
    _contexts = [contexts copy];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *extInfo = [NSString stringWithFormat:@"esports-platform/iPhone/%@", appVersion];
    NSString *jsBridgeInfo = @"Alisports-JSBridge/iPhone/2.0.0";
    NSString *newUserAgent = [NSString stringWithFormat:@"%@ %@", extInfo, jsBridgeInfo];
    [self.webView setWebViewType:AEWebViewContainTypeUIWebView];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    [self.webView setupCustomUserAgent:newUserAgent completionHandler:^(NSString *userAgent) {
        NSLog(@"User agent has been setup./n%@", userAgent);
    }];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_currentUrl]]];
    NSLog(@"---%@",self.webView);
    self.handler = [[AEJavaScriptHandler alloc] initWithPerformer:_manager];
    [self.webView setJavaScriptHandler:self.handler];
    if (_contexts) {
        [self.handler addJSContexts:_contexts];
    }
  
    
    NSHTTPCookie *cookie1 = [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName:@"TestCookieName1", NSHTTPCookieValue:@"TestCookieValue1", NSHTTPCookieDomain:@"alisports.com", NSHTTPCookiePath:@"/"}];
    NSHTTPCookie *cookie2 = [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName:@"TestCookieName2", NSHTTPCookieValue:@"TestCookieValue2", NSHTTPCookieDomain:@"alisports.com", NSHTTPCookiePath:@"/"}];
    [self.webView setCookies:@[cookie1, cookie2]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
}

- (void)testInstanceFunctionName:(NSString *)name var:(NSString *)var {
    NSString *functionName = [NSString stringWithUTF8String:__FUNCTION__];
    functionName = [[functionName componentsSeparatedByString:@" "] lastObject];
    functionName = [functionName substringToIndex:[functionName length] - 1];
    NSLog(@"%@", functionName);
    NSLog(@"%@", self);
}

- (void)testInstanceFunctionName2:(NSString *)name var2:(NSString *)var {
    
}

+ (void)testClassFunctionName2:(NSString *)name var2:(NSString *)var {
    
}

+ (void)testClassFunctionName:(NSString *)name var:(NSString *)va {
    NSString *functionName = [NSString stringWithUTF8String:__FUNCTION__];
    functionName = [[functionName componentsSeparatedByString:@" "] lastObject];
    functionName = [functionName substringToIndex:[functionName length] - 1];
    NSLog(@"%@", functionName);
    NSLog(@"%@", self);
}

- (void)aesSetTitle:(id)body {
    __weak typeof(self) weakSelf = self;;
    [weakSelf handleJSParam:body withResult:^(NSDictionary *jsCallBody, AESJSCallBack *callBack) {
        NSString *str = jsCallBody[@"title"];
        weakSelf.navigationItem.title = str;
        NSLog(@"set title:%@", str);
    }];
}

- (void)handleJSParam:(id)param withResult:(void (^)(NSDictionary *, AESJSCallBack *))result {
    if (!result) {
        return;
    }
    if (!param || ![param isKindOfClass:[NSDictionary class]]) {
        result(nil, nil);
        return;
    }
    NSDictionary *jsParam = [param objectForKey:@"parameter"];
    if (![jsParam isKindOfClass:[NSDictionary class]]) {
        jsParam = nil;
    }
    NSDictionary *callBackData = [param objectForKey:@"callback"];
    AESJSCallBack *callBack = [AESJSCallBack callBackWithRawData:callBackData];
    result(jsParam, callBack);
}

- (UIViewController *)configJSBridgePluginWithUrl:(NSString *)url{
    _currentUrl = url;
    return self;
}

- (AEWebViewContainer *)webView{
    if (_webView == nil) {
        _webView = [[AEWebViewContainer alloc]initWithFrame:self.view.frame];
        [self.view addSubview:_webView];
    }
    return _webView;
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(void (^)(id))callback{
    //todo
    [self.webView evaluateJavaScript:nil completionHandler:^(id completion, NSError *error) {
        
    }];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
