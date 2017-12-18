//
//  H5WebViewController.m
//  NebulaDemo
//
//  Created by Glance on 16/12/14.
//  Copyright © 2016年 Alipay. All rights reserved.
//
#import "NebulaSDKPluginHeader.h"
#import "H5WebViewController.h"

#ifdef ALS_HAS_NebulaSDK 

@interface H5WebViewController ()<PSDPluginProtocol>

@end

#endif

#ifdef ALS_HAS_NebulaSDK 
@implementation H5WebViewController

#pragma mark - UIViewController LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"[NebulaDemo]: 容器中的一个Scene被打开");
//    PSDJsApiConfig *jsApiConfig = [PSDJsApiConfig jsApiCfgWithHandlerBlock:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
//        //NSLog(@"...remoteLog...");
//        NSLog(@"...davidCustom...");
//    } jsApi:@"davidCustom"];
//    [NBServiceGet() registerJSApiCfg:jsApiConfig];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


#pragma mark - 自定义导航栏时的点击事件实现

- (IBAction)btnBackItemClicked:(id)sender
{
    if (self.navigationController) {
        NSMutableArray *arr = [[self.navigationController viewControllers] mutableCopy];
        [arr removeLastObject];
        
        [self.navigationController setViewControllers:arr animated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)btnRightItemClicked:(id)sender
{
    NSLog(@"[NebulaDemo]: 导航栏右侧按钮被点击");
}

#pragma mark - 注册为容器插件
- (void)nbViewControllerInit
{
    PSDSession *session = [self viewControllerProxy].psdSession;
    [session addEventListener:kEvent_Navigation_All
                 withListener:self
                   useCapture:NO];
    [session addEventListener:kEvent_Page_All
                 withListener:self
                   useCapture:NO];
    
}

- (NSString *)name
{
    return NSStringFromClass([self class]);
}

#pragma mark - 对应UIWebViewDelegate的委托实现

- (void)handleEvent:(PSDEvent *)event
{
    if (![[event.context currentViewController] isEqual:self]) {
        return;
    }
    if ([kEvent_Navigation_Start isEqualToString:event.eventType]) {
        BOOL shouldStart = [self handleContentViewShouldStartLoad:(id)event ];
        
        if (!shouldStart) {
            [event preventDefault];
        }
    }
    else if ([kEvent_Page_Load_Start isEqualToString:event.eventType]) {
        [self handleContentViewDidStartLoad:(id)event];
    }
    else if ([kEvent_Page_Load_Complete isEqualToString:event.eventType]) {
        [self handleContentViewDidFinishLoad:(id)event];
    }
    else if ([kEvent_Navigation_Error isEqualToString:event.eventType]) {
        [self handleContentViewDidFailLoad:(id)event];
    }
    else if ([kNBEvent_Scene_NavigationItem_Left_Back_Click isEqualToString:event.eventType]) {
        
    }
}


- (BOOL)handleContentViewShouldStartLoad:(PSDNavigationEvent *)event
{
    return YES;
}

- (void)handleContentViewDidStartLoad:(PSDPageEvent *)event
{
    
}

- (void)handleContentViewDidFinishLoad:(PSDPageEvent *)event
{
    
}

- (void)handleContentViewDidFailLoad:(PSDNavigationEvent *)event
{
    
}

@end

#endif
