//
//  NAMParamCenter.h
//  NebulaAppManager
//
//  Created by 扶瑶 on 2017/2/24.
//  Copyright © 2017年 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NAMParamCenter : NSObject

// 下载类型 (支持启动参数+扩展参数)
+ (NAMActionOfflineType)actionOfflineType:(NSDictionary *)info;

// 请求类型 (支持启动参数+扩展参数)
+ (NAMActionReqType)actionReqType:(NSDictionary *)info;

// 请求时间限制
+ (NSTimeInterval)prepareLimit:(NAMApp *)app force:(BOOL)force;

@end
