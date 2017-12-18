//
//  H5AlisPlugin.h
//  NebulaDemo
//
//  Created by Glance on 16/12/20.
//  Copyright © 2016年 Alipay. All rights reserved.
//


#import "NebulaSDKPluginHeader.h"

#ifdef ALS_HAS_NebulaSDK 

@interface H5AlisPlugin : NBPluginBase

@property(weak , nonatomic)NebulaSDKManager *manager;

@end

#endif
