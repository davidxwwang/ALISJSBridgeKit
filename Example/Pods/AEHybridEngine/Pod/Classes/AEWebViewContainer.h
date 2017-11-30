//
//  AEWebViewContainer.h
//  wesg
//
//  Created by Altair on 9/22/16.
//  Copyright © 2016 AliSports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

typedef enum {
    AEWebViewContainTypeWKWebView = 0,
    AEWebViewContainTypeUIWebView
}AEWebViewContainType;

typedef enum {
    AEWebViewNavigationTypeLinkClicked,
    AEWebViewNavigationTypeFormSubmitted,
    AEWebViewNavigationTypeBackForward,
    AEWebViewNavigationTypeReload,
    AEWebViewNavigationTypeFormResubmitted,
    AEWebViewNavigationTypeOther
}AEWebViewNavigationType;

@class AEWebViewContainer;
@class AEJavaScriptHandler;

@protocol AEWebviewContainerDelegate <NSObject>

@optional

//processing

- (BOOL)webViewContainer:(AEWebViewContainer *)container shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(AEWebViewNavigationType)navigationType webViewType:(AEWebViewContainType)webViewType;

- (void)webViewContainerDidStartLoad:(AEWebViewContainer *)container webViewType:(AEWebViewContainType)webViewType;

- (void)webViewContainerDidFinishLoad:(AEWebViewContainer *)container webViewType:(AEWebViewContainType)webViewType;

- (void)webViewContainer:(AEWebViewContainer *)container didFailLoadWithError:(NSError *)error webViewType:(AEWebViewContainType)webViewType;

//layout

- (void)webViewContainer:(AEWebViewContainer *)container needShowAlert:(UIAlertController *)alert withMessage:(NSString *)message;

@end

/**
 一个WebView容器，封装了UIWebView和WKWebView的常用方法和属性
 */
@interface AEWebViewContainer : UIView

@property (nonatomic, strong, readonly) UIView *webView;

@property (nonatomic, strong, readonly) UIScrollView *scrollView;

@property (nonatomic, assign) AEWebViewContainType webViewType;

@property (nonatomic, weak) id<AEWebviewContainerDelegate> delegate;

//webview methods
@property (nonatomic, strong, readonly) NSURLRequest *originalUrlRequest;   //原始请求
@property (nonatomic, strong, readonly) NSURLRequest *currentUrlRequest;    //当前的请求，即当前shouldStartLoad发起的请求
@property (nonatomic, strong, readonly) NSURL *currentUrl;  //当前的url

@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;

- (void)loadRequest:(NSURLRequest *)request;

- (void)reload;

- (void)reloadFromOrigin;

- (void)stopLoading;

- (void)goBack;

- (void)goForward;

- (void)clearWebCache:(void(^)(void))finished;

@end

/**
 对JavaScript相关功能的扩展
 */
@interface AEWebViewContainer (JavaScript)

@property (nonatomic, strong) AEJavaScriptHandler *javaScriptHandler;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id completion, NSError * error))completionHandler;

@end

/**
 对NSHTTPURLRequest的相关功能扩展
 */
@interface AEWebViewContainer (NSHTTPURLRequest)

@property (nonatomic, copy) NSArray<NSHTTPCookie *> *cookies;

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *customRequestHeaderFields;

- (void)setupCustomUserAgent:(NSString *)cUA completionHandler:(void(^)(NSString *userAgent))completionHandler;

- (NSString *)userAgent;

@end

/**
 WKWebView对JSHandler的扩展
 */
@interface WKWebView (AEWebView)

@property (nonatomic, readonly) BOOL canSetupJSHandle;

@end

/**
 UIWebView对JSHandler的扩展
 */
@interface UIWebView (AEWebView)

@property (nonatomic, readonly) BOOL canSetupJSHandle;

@end
