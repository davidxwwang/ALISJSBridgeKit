//
//  AEJavaScriptHandler.h
//  TestWebViewContainer
//
//  Created by Altair on 12/06/2017.
//  Copyright © 2017 Alisports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class AEJSHandlerContext;
@class AEJavaScriptHandler;

NS_ASSUME_NONNULL_BEGIN

#pragma mark AEJavaScriptHandler

@interface AEJavaScriptHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, copy) NSSet<AEJSHandlerContext *> *__nullable jsContexts;    //当前handle的context对象集合。调用setter方法后，即会注册对应的native方法。注1：对于WKWebView，建议在load之前就设置；而UIWebView，建议在finishLoad时设置。注2：如果不同的performer定义了相同的selector，则在找到第一个可处理的performer后，会停止遍历。

@property (nonatomic, copy) void(^ HandledContextsChanged)(AEJavaScriptHandler *handler);   //当jsContexts集合发生改变后，会调用该block

@property (nonatomic, assign) BOOL autoFillable;    //是否支持自动添加JSContexts，默认YES

- (BOOL)addJSContexts:(NSSet<AEJSHandlerContext *> *)contexts;

- (void)removeJSContextsForPerformer:(id)performer;

- (void)removeJSContextsWithSEL:(SEL)selector;

- (void)removeJSContextsWithAliasName:(NSString *)name;

- (NSArray *)performers;

/**
 响应调用JSContext

 @param context context
 @return 是否找到对应的native方法并执行
 */
- (BOOL)responseToCallWithJSContext:(AEJSHandlerContext *)context;

/**
 响应JS调用的方法，该方法被主动调起后，会执行相关的本地操作，从而自动执行jsContext中对应的native方法

 @param message WebKit中定义的script消息对象
 @return 是否找到对应的native方法并执行
 */
- (BOOL)responseToJSCallWithScriptMessage:(WKScriptMessage *)message;

/**
 获取当前活动的JSHandler

 @return 当前活动的JSHandler
 */
+ (NSArray<AEJavaScriptHandler *> * __nullable __autoreleasing)activeHandlers;

@end

#pragma mark AEJSHandlerContext

@interface AEJSHandlerContext : NSObject <NSCopying>

@property (nonatomic, copy) NSString *__nullable aliasName;    //context别名。由于selector有无参数的时候转化的string值不一样，所以会优先使用别名来注册JS调用的方法，如果别名没有赋值，则使用selector来注册。

@property (nonatomic, strong) id args;  //执行该Native方法的参数

/**
 判断与指定JSContext是否一样
 
 @param object 指定JSContext
 @return 是否一样
 */
- (BOOL)isEqual:(id)object;

/**
 判断是否有效
 
 @return 是否有效
 */
- (BOOL)isValid;

@end

@interface AEJSHandlerPerformerContext : AEJSHandlerContext

@property (nonatomic, weak) id performer;   //方法执行者，为类实例或者类。根据实际执行SEL的类型来赋值。必填

@property (nonatomic, assign) SEL selector; //调用的Native方法。如果是实例方法，则performer需赋值实例，如果是类方法，则performer需赋值类。必填

/**
 便捷生成context对象的方法

 @param performer 类实例或者类
 @param selector 调用的native方法
 @return context对象实例
 */
+ (instancetype)contextWithPerformer:(id)performer selector:(SEL)selector aliasName:(NSString *__nullable)aliasName;

@end

@interface AEJSHandlerBlockContext : AEJSHandlerContext

@property (nonatomic, copy) void(^ JSCallback)(AEJSHandlerBlockContext *context);   //调用的block回调，必填

+ (instancetype)contextWithAliasName:(NSString *__nullable)aliasName jsCallback:(void(^)(AEJSHandlerBlockContext *context))callback;

@end

#pragma mark WeakScriptMessageDelegate

/**
 弱引用的消息代理，用于WKWebView
 */
@interface WeakScriptMessageDelegate : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

NS_ASSUME_NONNULL_END
