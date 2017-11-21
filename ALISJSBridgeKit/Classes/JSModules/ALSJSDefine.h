//
//  ALSJSDefine.h
//  david_NebulaSDKDemo
//
//  Created by alisports on 2017/11/17.
//  Copyright © 2017年 alisports.sportsman. All rights reserved.
//

#ifndef ALSJSDefine_h
#define ALSJSDefine_h

#if defined(__cplusplus)
#define JS_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define JS_EXTERN extern __attribute__((visibility("default")))
#endif

#endif /* ALSJSDefine_h */
