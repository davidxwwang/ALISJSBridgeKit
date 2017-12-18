//
//  NebulaSDKPluginHeader.h
//  Pods
//
//  Created by alisports on 2017/12/8.
//

#ifndef NebulaSDKPluginHeader_h
#define NebulaSDKPluginHeader_h

#if __has_include(<NebulaSDK/NebulaSDK.h>)
#define ALS_HAS_NebulaSDK
#endif

#ifdef ALS_HAS_NebulaSDK
#import <NebulaSDK/NebulaSDK.h>
#import <NebulaSDK/NBPluginBase.h>
#endif

#endif /* NebulaSDKPluginHeader_h */
