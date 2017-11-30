//
//  AEWebViewContainer.m
//  wesg
//
//  Created by Altair on 9/22/16.
//  Copyright © 2016 AliSports. All rights reserved.
//
#import "AEWebViewContainer.h"
#import <objc/runtime.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "AEJavaScriptHandler.h"
#import "AEWebCookieStorage.h"

#define AEWEBVIEW_JSHANDLE_SETUPKEY (@"canSetupJSHandle")

#pragma mark WKWebview (AEWebView)

@implementation WKWebView (AEWebView)

- (void)setCanSetupJSHandle:(BOOL)canSetupJSHandle {
    NSNumber *can = [NSNumber numberWithBool:canSetupJSHandle];
    [self willChangeValueForKey:@"canSetupJSHandle"];
    objc_setAssociatedObject(self, @"AEWebView_WKWebView_CanSetupJSHandle", can, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"canSetupJSHandle"];
}

- (BOOL)canSetupJSHandle {
    NSNumber *can = objc_getAssociatedObject(self, @"AEWebView_WKWebView_CanSetupJSHandle");
    return [can boolValue];
}

@end

#pragma mark UIWebview (AEWebView)

@implementation UIWebView (AEWebView)

- (void)setCanSetupJSHandle:(BOOL)canSetupJSHandle {
    NSNumber *can = [NSNumber numberWithBool:canSetupJSHandle];
    [self willChangeValueForKey:@"canSetupJSHandle"];
    objc_setAssociatedObject(self, @"AEWebView_UIWebView_CanSetupJSHandle", can, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"canSetupJSHandle"];
}

- (BOOL)canSetupJSHandle {
    NSNumber *can = objc_getAssociatedObject(self, @"AEWebView_UIWebView_CanSetupJSHandle");
    return [can boolValue];
}

@end



#pragma mark AEWebViewContainer

@interface AEWebViewContainer () <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *uiWebView;

@property (nonatomic, strong) WKWebView *wkWebView;   //默认

@property (nonatomic, strong) JSContext *uiWebViewJSContext;

@property (nonatomic, copy) NSString *currentUA;

- (void)setupWebView;

- (WKWebViewConfiguration *)wkWebViewConfiguration;

@end

#pragma mark AEWebViewContainer (JavaScript)

@implementation AEWebViewContainer (JavaScript)

- (void)setJavaScriptHandler:(AEJavaScriptHandler *)javaScriptHandler {
    [self removeJavaScriptHandler:self.javaScriptHandler];
    if (javaScriptHandler!= self.javaScriptHandler) {
        objc_setAssociatedObject(self, @"AEWebViewContainer_JavaScriptHandler", javaScriptHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        //不同的jshandler，需要重新添加一遍
        [self addJavaScriptHandler:self.javaScriptHandler];
    }
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(self.javaScriptHandler) weakHandler = self.javaScriptHandler;
    self.javaScriptHandler.HandledContextsChanged = ^(AEJavaScriptHandler * _Nonnull handler) {
        //如果关联的jscontext变了，需要重新添加一遍
        [weakSelf removeJavaScriptHandler:weakHandler];
        [weakSelf addJavaScriptHandler:weakHandler];
    };
}

- (AEJavaScriptHandler *)javaScriptHandler {
    return objc_getAssociatedObject(self, @"AEWebViewContainer_JavaScriptHandler");
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id completion, NSError * error))completionHandler {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            NSString *compString = [self.uiWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
            if (completionHandler) {
                NSError *err = nil;
                if (!compString) {
                    err = [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:@{NSLocalizedDescriptionKey : @"执行JS语句失败"}];
                }
                completionHandler(compString, err);
            }
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
        }
            break;
        default:
            break;
    }
}

- (BOOL)addJavaScriptHandler:(AEJavaScriptHandler *)handler {
    if (!self.webView || !handler || !handler.performer || [handler.jsContexts count] == 0) {
        return NO;
    }
    
    //注册JS
    if ([self.webView isKindOfClass:[WKWebView class]] && ((WKWebView *)self.webView).canSetupJSHandle) {
        WKWebView *wkWebView = (WKWebView *)self.webView;
        //WKWebView
        WeakScriptMessageDelegate *delegate = [[WeakScriptMessageDelegate alloc] initWithDelegate:handler];
        if (delegate) {
            for (AEJSHandlerContext *jsContext in handler.jsContexts) {
                if ([jsContext isKindOfClass:[AEJSHandlerPerformerContext class]] &&
                    !object_isClass(((AEJSHandlerPerformerContext *)jsContext).performer) &&
                    ((AEJSHandlerPerformerContext *)jsContext).performer != handler.performer) {
                    //只注册类方法，和对应performer的实例方法，否则不注册
                    continue;
                }
                if ([jsContext isKindOfClass:[AEJSHandlerBlockContext class]] && !((AEJSHandlerBlockContext *)jsContext).JSCallback) {
                    //block类型，如果为nil则不注册
                    continue;
                }
                if ([jsContext.aliasName length] > 0) {
                    [wkWebView.configuration.userContentController addScriptMessageHandler:handler name:jsContext.aliasName];
                } else if ([jsContext isKindOfClass:[AEJSHandlerPerformerContext class]] && ((AEJSHandlerPerformerContext *)jsContext).selector) {
                    [wkWebView.configuration.userContentController addScriptMessageHandler:delegate name:NSStringFromSelector(((AEJSHandlerPerformerContext *)jsContext).selector)];
                }
            }
            return YES;
        }
        return NO;
    } else if ([self.webView isKindOfClass:[UIWebView class]] && ((UIWebView *)self.webView).canSetupJSHandle) {
        UIWebView *uiWebView = (UIWebView *)self.webView;
        //UIWebView
        self.uiWebViewJSContext = [uiWebView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        //打印异常
        self.uiWebViewJSContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
            context.exception = exceptionValue;
            NSLog(@"%@", exceptionValue);
        };
        __weak typeof(self) weakSelf = self;
        [handler.jsContexts enumerateObjectsUsingBlock:^(AEJSHandlerContext *context, BOOL * stop) {
            if ([context isKindOfClass:[AEJSHandlerPerformerContext class]] &&
                !object_isClass(((AEJSHandlerPerformerContext *)context).performer) &&
                ((AEJSHandlerPerformerContext *)context).performer != handler.performer) {
                //只注册类方法，和对应performer的实例方法，否则不注册
                return;
            }
            if ([context isKindOfClass:[AEJSHandlerBlockContext class]] && !((AEJSHandlerBlockContext *)context).JSCallback) {
                //block类型，如果为nil则不注册
                return;
            }
            NSString *methodName = context.aliasName;
            if ([methodName length] == 0) {
                if ([context isKindOfClass:[AEJSHandlerPerformerContext class]] &&
                    ((AEJSHandlerPerformerContext *)context).selector) {
                    methodName = NSStringFromSelector(((AEJSHandlerPerformerContext *)context).selector);
                } else {
                    return;
                }
            }
            if ([methodName length] > 0) {
                weakSelf.uiWebViewJSContext[methodName] = ^ {
                    //提取参数
                    NSArray *args = [JSContext currentArguments];
                    if ([args count] == 1) {
                        context.args = [[args firstObject] toObject];
                    } else {
                        NSMutableArray *temp = [[NSMutableArray alloc] init];
                        for (JSValue *value in args) {
                            id argObj = [value toObject];
                            if (argObj) {
                                [temp addObject:argObj];
                            }
                        }
                        if ([temp count] == 1) {
                            context.args = [temp firstObject];
                        } else {
                            context.args = [temp copy];
                        }
                    }
                    //主线程调用
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [handler responseToCallWithJSContext:context];
                    });
                    
                };
            }
        }];
        return YES;
    }
    return NO;
}

- (void)removeJavaScriptHandler:(AEJavaScriptHandler *)handler {
    if (!self.wkWebView || !handler) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (AEJSHandlerContext *jsContext in handler.jsContexts) {
            if ([jsContext.aliasName length] > 0) {
                [[self.wkWebView configuration].userContentController removeScriptMessageHandlerForName:jsContext.aliasName];
            } else if ([jsContext isKindOfClass:[AEJSHandlerPerformerContext class]] && ((AEJSHandlerPerformerContext *)jsContext).selector) {
                [[self.wkWebView configuration].userContentController removeScriptMessageHandlerForName:NSStringFromSelector(((AEJSHandlerPerformerContext *)jsContext).selector)];
            }
        }
    });
}

@end

#pragma mark AEWebViewContainer (NSHTTPURLRequest)

@implementation AEWebViewContainer (NSHTTPURLRequest)

- (void)setCookies:(NSArray<NSHTTPCookie *> *)cookies {
    objc_setAssociatedObject(self, @"AEWebViewContainer_Cookies", cookies, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (cookies) {
        for (NSHTTPCookie *cookie in cookies) {
            [[AEWebCookieStorage sharedCookieStorage] setCookie:cookie];
        }
    } else {
        NSArray *willDeleteCookies = [AEWebCookieStorage sharedCookieStorage].cookies;
        [self deleteCookies:willDeleteCookies];
        [[AEWebCookieStorage sharedCookieStorage] removeAllCookies];
    }
}

- (NSArray<NSHTTPCookie *> *)cookies {
    return objc_getAssociatedObject(self, @"AEWebViewContainer_Cookies");
}

- (void)setCustomRequestHeaderFields:(NSDictionary<NSString *,NSString *> *)customRequestHeaderFields {
    objc_setAssociatedObject(self, @"AEWebViewContainer_CustomRequestHeaderFields", customRequestHeaderFields, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary<NSString *, NSString *> *)customRequestHeaderFields {
    return objc_getAssociatedObject(self, @"AEWebViewContainer_CustomRequestHeaderFields");
}

- (void)setupCustomUserAgent:(NSString *)cUA completionHandler:(void (^)(NSString *))completionHandler {
    if (self.webViewType == AEWebViewContainTypeWKWebView) {
        __weak typeof(self) weakSelf = self;
        [weakSelf.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id completion, NSError * error) {
            if (!error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                NSString *userAgent = completion;
                
                NSUInteger extLocation = [userAgent rangeOfString:cUA].location;
                if (extLocation != NSNotFound && extLocation > 1) {
                    //发现已设置cUA，则清空设置的cUA，并设置WK的（包括一个空格）
                    userAgent = [userAgent substringToIndex:extLocation - 1];
                }
                
                userAgent = [NSString stringWithFormat:@"%@ %@/WK", userAgent, cUA];
                
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
                strongSelf.wkWebView.customUserAgent = userAgent;
#else
                [strongSelf.wkWebView setValue:userAgent forKey:@"applicationNameForUserAgent"];
#endif
                self.currentUA = userAgent;
                if (completionHandler) {
                    completionHandler(userAgent);
                }
            }
        }];
    } else {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        NSUInteger extLocation = [userAgent rangeOfString:cUA].location;
        if (extLocation != NSNotFound && extLocation > 1) {
            //发现已设置cUA，则清空设置的cUA，并设置UI的（包括一个空格）
            userAgent = [userAgent substringToIndex:extLocation - 1];
        }
        
        userAgent = [NSString stringWithFormat:@"%@ %@/UI", userAgent, cUA];
        NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:userAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
        self.currentUA = userAgent;
        if (completionHandler) {
            completionHandler(userAgent);
        }
    }
}

- (NSString *)userAgent {
    return self.currentUA;
}

- (void)injectCookies {
    NSArray<NSHTTPCookie *> *cookies = [AEWebCookieStorage sharedCookieStorage].cookies;
    for (NSHTTPCookie *cookie in cookies) {
        NSString *jsString = [NSString stringWithFormat:@"document.cookie=\'%@=%@\'", cookie.name, cookie.value];
        [self evaluateJavaScript:jsString completionHandler:^(id completion, NSError *error) {
            NSLog(@"%@", error);
        }];
    }
}

- (void)deleteCookies:(NSArray<NSHTTPCookie *> *)cookies {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    for (NSHTTPCookie *cookie in cookies) {
        NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:-100];
        NSString *expireTimeString = [formatter stringFromDate:expireDate];
        NSString *jsString = [NSString stringWithFormat:@"document.cookie=\'%@=%@;expires=%@\'", cookie.name, cookie.value, expireTimeString];
        [self evaluateJavaScript:jsString completionHandler:^(id completion, NSError *error) {
            NSLog(@"%@", error);
        }];
    }
}

@end

#pragma mark AEWebViewContainer

@implementation AEWebViewContainer
@synthesize currentUrlRequest = _currentUrlRequest;

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!self.wkWebView && !self.uiWebView) {
        //默认WKWebView
        [self setWebViewType:AEWebViewContainTypeWKWebView];
    }
}

- (void)dealloc{
    self.wkWebView.navigationDelegate = nil;
    self.wkWebView.UIDelegate = nil;
    self.wkWebView.scrollView.delegate = nil;
//    [self removeJavaScriptHandler:self.javaScriptHandler];  //webview被销毁，不需要再移除handler
    [self.wkWebView removeObserver:self forKeyPath:AEWEBVIEW_JSHANDLE_SETUPKEY];
    
    self.uiWebView.delegate = nil;
    self.uiWebView.scrollView.delegate = nil;
    [self.uiWebView removeObserver:self forKeyPath:AEWEBVIEW_JSHANDLE_SETUPKEY];
}

#pragma mark Getter & Setter

- (void)setWebViewType:(AEWebViewContainType)webViewType {
    if (webViewType == _webViewType && (self.uiWebView || self.wkWebView)) {
        //type相同，并且有一种webview已经初始化过，则直接返回
        return;
    }
    _webViewType = webViewType;
    [self setupWebView];
}

- (NSURLRequest *)currentUrlRequest {
    NSURLRequest *urlRequest = nil;
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            urlRequest = self.uiWebView.request;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            if (_currentUrlRequest) {
                urlRequest = _currentUrlRequest;
            } else {
                urlRequest = [NSURLRequest requestWithURL:self.wkWebView.URL];
            }
        }
            break;
        default:
            break;
    }
    return urlRequest;
}

- (NSURL *)currentUrl {
    NSURL *url = nil;
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            url = self.uiWebView.request.URL;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            url = self.wkWebView.URL;
        }
            break;
        default:
            break;
    }
    return url;
}

- (BOOL)canGoBack {
    BOOL can = NO;
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            can = self.uiWebView.canGoBack;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            can = self.wkWebView.canGoBack;
        }
            break;
        default:
            break;
    }
    return can;
}

- (BOOL)canGoForward {
    BOOL can = NO;
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            can = self.uiWebView.canGoForward;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            can = self.wkWebView.canGoForward;
        }
            break;
        default:
            break;
    }
    return can;
}

- (BOOL)isLoading {
    BOOL loading = NO;
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            loading = self.uiWebView.isLoading;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            loading = self.wkWebView.isLoading;
        }
            break;
        default:
            break;
    }
    return loading;
}

- (UIView *)webView {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            return _uiWebView;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            return _wkWebView;
        }
            break;
        default:
            break;
    }
    return nil;
}

- (UIScrollView *)scrollView{
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            return _uiWebView.scrollView;
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            return _wkWebView.scrollView;
        }
            break;
        default:
            break;
    }
    return nil;
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainer:shouldStartLoadWithRequest:navigationType:webViewType:)]) {
        NSInteger type = navigationAction.navigationType;
        if (type == -1) {
            type = AEWebViewNavigationTypeOther;
        }
        BOOL should = [self.delegate webViewContainer:self shouldStartLoadWithRequest:navigationAction.request navigationType:(AEWebViewNavigationType)type webViewType:AEWebViewContainTypeWKWebView];
        if (!should) {
            policy = WKNavigationActionPolicyCancel;
        }
    }
    if (decisionHandler) {
        decisionHandler(policy);
    }
    if (policy == WKNavigationActionPolicyAllow) {
        _currentUrlRequest = [navigationAction.request copy];
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainerDidStartLoad:webViewType:)]) {
        [self.delegate webViewContainerDidStartLoad:self webViewType:AEWebViewContainTypeWKWebView];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    //注入cookie
    [self injectCookies];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainerDidFinishLoad:webViewType:)]) {
        [self.delegate webViewContainerDidFinishLoad:self webViewType:AEWebViewContainTypeWKWebView];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainer:didFailLoadWithError:webViewType:)]) {
        [self.delegate webViewContainer:self didFailLoadWithError:error webViewType:AEWebViewContainTypeWKWebView];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{

}

#pragma mark WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        completionHandler();
        
    }]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainer:needShowAlert:withMessage:)]) {
        [self.delegate webViewContainer:self needShowAlert:alert withMessage:message];
    }
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainer:shouldStartLoadWithRequest:navigationType:webViewType:)]) {
        return [self.delegate webViewContainer:self shouldStartLoadWithRequest:request navigationType:(AEWebViewNavigationType)navigationType webViewType:AEWebViewContainTypeUIWebView];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainerDidStartLoad:webViewType:)]) {
        [self.delegate webViewContainerDidStartLoad:self webViewType:AEWebViewContainTypeUIWebView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //js
    [self.uiWebView setCanSetupJSHandle:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainerDidFinishLoad:webViewType:)]) {
        [self.delegate webViewContainerDidFinishLoad:self webViewType:AEWebViewContainTypeUIWebView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewContainer:didFailLoadWithError:webViewType:)]) {
        [self.delegate webViewContainer:self didFailLoadWithError:error webViewType:AEWebViewContainTypeUIWebView];
    }
}


#pragma mark UIScrollViewDelegate


#pragma mark Private methods

- (void)setupWebView {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            //initialization
            if (!_uiWebView) {
                _uiWebView= [[UIWebView alloc] init];
                [self.uiWebView setScalesPageToFit:YES];
                [self addSubview:self.uiWebView];
                [self.uiWebView setBackgroundColor:[UIColor clearColor]];
                [self setBackgroundColor:[UIColor clearColor]];
                
                //add constraint
                [self.uiWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
                NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];//+
                NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];//+
                NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];//-
                NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];//-
                
                [NSLayoutConstraint activateConstraints:@[left, right, top, bottom]];
                
                [_uiWebView addObserver:self forKeyPath:AEWEBVIEW_JSHANDLE_SETUPKEY options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
            }
            if (_wkWebView) {
                [_wkWebView stopLoading];
            }
            [self bringSubviewToFront:self.uiWebView];
            self.uiWebView.delegate = self;
            [self.uiWebView loadRequest:self.currentUrlRequest ? self.currentUrlRequest : self.originalUrlRequest];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            //initialization
            if (!_wkWebView) {
                _wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self wkWebViewConfiguration]];
                [self addSubview:self.wkWebView];
                [self.wkWebView setBackgroundColor:[UIColor clearColor]];
                [self setBackgroundColor:[UIColor clearColor]];
                
                //add constraint
                [self.wkWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
                NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];//+
                NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];//+
                NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];//-
                NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];//-
                
                [NSLayoutConstraint activateConstraints:@[left, right, top, bottom]];
                
                //js
                [_wkWebView addObserver:self forKeyPath:AEWEBVIEW_JSHANDLE_SETUPKEY options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
            }
            if (_uiWebView) {
                [_uiWebView stopLoading];
            }
            [self.wkWebView setCanSetupJSHandle:YES];
            [self bringSubviewToFront:self.wkWebView];
            self.wkWebView.UIDelegate = self;
            self.wkWebView.navigationDelegate = self;
            [self.wkWebView loadRequest:self.currentUrlRequest ? self.currentUrlRequest : self.originalUrlRequest];
        }
            break;
        default:
            break;
    }
}

- (WKWebViewConfiguration *)wkWebViewConfiguration {
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);)";
    
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = wkUController;
    config.allowsInlineMediaPlayback = YES;
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;

    if ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"8."]) {
        config.mediaPlaybackRequiresUserAction = NO;
    } else if ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"9."]) {
        config.requiresUserActionForMediaPlayback = NO;
    } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeVideo;
#endif
    }
    
    return config;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:AEWEBVIEW_JSHANDLE_SETUPKEY] && self.javaScriptHandler) {
        [self addJavaScriptHandler:self.javaScriptHandler];
    }
}

#pragma mark Publick methods

- (void)loadRequest:(NSURLRequest *)request {
    NSMutableURLRequest *fitRequest = [request mutableCopy];
    //User-Agent
    [fitRequest setValue:[self currentUA] forHTTPHeaderField:@"User-Agent"];
    //Header
    [self.customRequestHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [fitRequest setValue:obj forHTTPHeaderField:key];
    }];
    //Cookie
    _originalUrlRequest = [[AEWebCookieStorage sharedCookieStorage] cookiedRequest:fitRequest];
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [self.uiWebView loadRequest:_originalUrlRequest];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView loadRequest:_originalUrlRequest];
        }
            break;
        default:
            break;
    }
}

- (void)reload {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [self.uiWebView reload];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView reload];
        }
            break;
        default:
            break;
    }
}

- (void)reloadFromOrigin {
    _currentUrlRequest = nil;
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [self.uiWebView loadRequest:self.originalUrlRequest];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView loadRequest:self.originalUrlRequest];
        }
            break;
        default:
            break;
    }
}

- (void)stopLoading {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [self.uiWebView stopLoading];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView stopLoading];
        }
            break;
        default:
            break;
    }
}

- (void)goBack {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [self.uiWebView goBack];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView goBack];
        }
            break;
        default:
            break;
    }
}

- (void)goForward {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [self.uiWebView goForward];
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            [self.wkWebView goForward];
        }
            break;
        default:
            break;
    }
}

- (void)clearWebCache:(void (^)(void))finished {
    switch (self.webViewType) {
        case AEWebViewContainTypeUIWebView:
        {
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            if (finished) {
                finished();
            }
        }
            break;
        case AEWebViewContainTypeWKWebView:
        {
            if (![[[UIDevice currentDevice] systemVersion] hasPrefix:@"8."]) {
                [self.wkWebView.configuration.websiteDataStore removeDataOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:finished ? finished : ^{}];
            }
        }
            break;
        default:
        {
            if (finished) {
                finished();
            }
        }
            break;
    }
}

@end


