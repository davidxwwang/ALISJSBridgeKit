//
//  PSDConfiguration.h
//  NebulaPoseidon
//
//  Created by chenwenhong on 15/10/12.
//  Copyright © 2015年 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PSDLoggerProtocol;
@class WKWebViewConfiguration;

@interface PSDConfiguration : NSObject

@property(nonatomic, readonly, copy) NSString      *sdkVersion;
@property(nonatomic, copy) NSString      *pluginsBundleName;
@property(nonatomic, copy) NSString      *extraPluginsFilePath;
@property(nonatomic, weak) id<PSDLoggerProtocol> logger;
@property(nonatomic, strong) WKWebViewConfiguration *wkConfiguration;
@property(nonatomic, assign) BOOL        shouldUseJSCInjectJS;
@property(nonatomic, assign) BOOL        shouldSyncWKCookie;

+ (instancetype)defaultConfiguration;

//禁止创建实例
+ (instancetype)alloc UNAVAILABLE_ATTRIBUTE;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (id)copy UNAVAILABLE_ATTRIBUTE;

+ (instancetype)allocWithZone:(struct _NSZone *)zone UNAVAILABLE_ATTRIBUTE;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus
    
    PSDConfiguration * PSDConfigurationGet();
    
#ifdef __cplusplus
}
#endif // __cplusplus
