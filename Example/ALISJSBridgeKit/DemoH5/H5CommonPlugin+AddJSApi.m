//
//  H5CommonPlugin+AddJSApi.m
//  alisports.sportsman
//
//  Created by alisports on 2017/11/2.
//  Copyright © 2017年 alisports. All rights reserved.
//
#import "NebulaSDKManager.h"
#import "H5CommonPlugin+AddJSApi.h"
#import <objc/runtime.h>

@implementation H5CommonPlugin (AddJSApi)

+ (void)load{
    
    if (!class_respondsToSelector([self class], @selector(addJSApis))) return;
    
    Method oldMethod = class_getInstanceMethod([self class], @selector(addJSApis));
    if (!oldMethod) return;    
    Method freshMethod = class_getInstanceMethod([self class], @selector(swizz_addJSApis));
    method_exchangeImplementations(oldMethod, freshMethod);
}

- (void)swizz_addJSApis{
    [self swizz_addJSApis];
    NSDictionary *dic = [self.manager addedExtraJSHandersDic];
    
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PSDJsApi *jsApiAlisMakeSegue = 
        [PSDJsApi jsApi:key
                handler:^(NSDictionary *data, PSDContext *context, PSDJsApiResponseCallbackBlock responseCallbackBlock) {
                    
                    PSDInvocationEvent *invokeEvent = (PSDInvocationEvent *)context.event;                    
                    AlisJSBridgeContext *alisContext = [[AlisJSBridgeContext alloc]init];
                    alisContext.orignalData = context;
                    alisContext.JSApiName = invokeEvent.jsApi.name;
                
                    [self handerJSCallBack:data context:alisContext responseCallbackBlock:responseCallbackBlock];
                }
            checkParams:NO
              isPrivate:NO
                  scope:self.scope];
        [self registerJsApi2Target:jsApiAlisMakeSegue];
        
    }];
}

- (void)handerJSCallBack:(id)data context:(AlisJSBridgeContext *)context responseCallbackBlock:(AlisJSApiResponseCallbackBlock) responseCallbackBlock{
    if ([self.manager respondsToSelector:@selector(handerJSCallBack:context:responseCallbackBlock:)]) {
        [self.manager handerJSCallBack:data context:context responseCallbackBlock:responseCallbackBlock];
    }
}

@end

