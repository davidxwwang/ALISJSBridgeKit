//
//  NBComponentProtocol.h
//  NebulaPlugins
//
//  Created by theone on 17/3/13.
//  Copyright © 2017年 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NBComponentCallback)(NSDictionary *data);

@class NBComponentContext;
@protocol NBComponentProtocol;


@protocol NBComponentMessageDelegate <NSObject>

@required
/**
 * 组件主动发送消息给页面(Native->Page)
 *
 * @param message 消息名称
 * @param component 要发送消息的组件
 * @param data 消息内容
 * @param callback 页面处理完消息后的回调
 *
 * @return void
 */
- (void)sendMessage:(NSString *)message
          component:(id<NBComponentProtocol>)component
               data:(NSDictionary *)data
           callback:(NBComponentCallback)callback;
@optional

/**
 * 组件可以在执行环境中直接执行JS
 *
 * @param javaScriptString 需要执行的JS
 * @param completionHandler 执行回调函数
 *
 * @return void
 */
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

@end

@protocol NBComponentLifeCycleProtocol <NSObject>

- (void)componentWillAppear;
- (void)componentDidAppear;
/**
 * 组件将要销毁
 *
 * @return void
 */
- (void)componentWillDestory;
/**
 * 组件销毁之后
 *
 * @return void
 */
- (void)componentDidDestory;
- (void)componentWillResume;
- (void)componentDidResume;
- (void)componentWillPause;
- (void)componentDidPause;
@end


@protocol NBComponentDataProtocol <NSObject>
/**
 * 组件数据将要更新
 *
 * @param data 数据内容
 *
 * @return void
 */
- (void)componentDataWillChangeWithData:(NSDictionary *)data;
/**
 * 组件数据已经更新，这时候一般是要作界面更新，或者组件的其他操作
 *
 * @param data 数据内容
 *
 * @return void
 */
- (void)componentDataDidChangeWithData:(NSDictionary *)data;
@end

@protocol NBComponentProtocol <NSObject,NBComponentLifeCycleProtocol,NBComponentDataProtocol>
@required
@property(nonatomic, weak) id<NBComponentMessageDelegate>  nbComponentMessageDelegate;
@property(nonatomic, strong)          NBComponentContext  *context;
@property(nonatomic, copy)            NSString *type;
@property(nonatomic, strong)          NSDictionary *data;
@property(nonatomic, copy)            NSString *componentId;

/**
 * NBComponent需要返回一个UIView对象
 * @return void
 */
- (UIView *)contentView;

/**
 * 组件收到页面发送过来的消息(Page->Native)
 *
 * @param message 消息名称
 * @param data 消息内容
 * @param callback 将Native处理后的结果返回给页面的回调函数
 *
 * @return void
 */
- (void)componentReceiveMessage:(NSString *)message
                          data:(NSDictionary *)data
                      callback:(NBComponentCallback)callback;
@end
