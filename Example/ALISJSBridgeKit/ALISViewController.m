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
    [[ALSJSBridgeModuleManager sharedBridge] launchJSSDKPlugins];
    [[ALSJSBridgeModuleManager sharedBridge] attachToBridge];
    
    UIViewController *vc = [[ALSJSBridgeModuleManager sharedBridge]  H5ViewControllerWithUrl:@"http://192.168.31.115:8080/nebula/"];
    
    
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:nil];
    
}


@end
