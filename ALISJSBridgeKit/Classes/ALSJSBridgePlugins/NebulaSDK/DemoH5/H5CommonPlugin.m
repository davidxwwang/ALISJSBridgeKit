//
//  H5CommonPlugin.m
//  alisports.sportsman
//
//  Created by alisports on 2017/11/2.
//  Copyright © 2017年 alisports. All rights reserved.
//

#import "H5CommonPlugin.h"


#ifdef ALS_HAS_NebulaSDK 
// 该插件已在Poseidon-Extra-Config.plist中注册
@implementation H5CommonPlugin

- (void)pluginDidLoad{
    NSLog(@"%s is called",__func__);
    self.scope = kPSDScope_Scene;
    
    [[NSNotificationCenter defaultCenter]postNotificationName:AlisNebulaSDKPluginDidLoadNotification object:self];
    
    [super pluginDidLoad];
}

- (void)addJSApis{
    [super addJSApis];
}

@end

#endif
