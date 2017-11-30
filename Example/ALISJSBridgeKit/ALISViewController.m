//
//  ALISViewController.m
//  ALISJSBridgeKit
//
//  Created by xwwang_0102@qq.com on 11/21/2017.
//  Copyright (c) 2017 xwwang_0102@qq.com. All rights reserved.
//

#import "ALISViewController.h"
#import <ALISJSBridgeKit/ALISJSBridgeKit.h>

@interface ALISViewController ()
{
    ALSJSBridgeModuleManager *yy;
}

@end

@implementation ALISViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ButtonTapped:(id)sender {
    
    //todo 也可以通过plist加载特定的plugin
//    [[ALSJSBridgeModuleManager sharedBridge] launchJSSDKPlugins];
//    [[ALSJSBridgeModuleManager sharedBridge] attachToBridge];
//    
    
    yy = [[ALSJSBridgeModuleManager alloc]init];
    [yy attachToBridge];
    //[yy launchJSSDKPlugins];
    //也可以使用plist NebulaSDKManager
    id<ALISBridgePluginProtocol> plugin = [yy pluginWithName:@"AEHybridEngineManager"];
    if (plugin) {
        plugin.priority = KALSJSPluginPriorityHigh;
    }
    //  @"http://192.168.31.115:8080/nebula/"
    UIViewController *vc = [yy H5ViewControllerWithUrl:@"http://testesports.alisports.com/static/demo/jsbridge1.0.0.html"];
    
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:nil];
    
}


@end
