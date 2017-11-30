//
//  AEHybridEngineViewController.h
//  PROJECT
//
//  Created by PROJECT_OWNER on TODAYS_DATE.
//  Copyright (c) TODAYS_YEAR PROJECT_OWNER. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AEHybridEngine/AEHybridEngine.h>
#import "AEHybridEngineManager.h"

@interface AEHybridEngineViewController : UIViewController

- (UIViewController *)configJSBridgePluginWithUrl:(NSString *)url;
    
+ (void)testClassFunctionName:(NSString *)name
                          var:(NSString *)var  AE_JSHANDLED_SELECTOR(testClassFunction);

+ (void)testClassFunctionName2:(NSString *)name
                          var2:(NSString *)var  AE_JSHANDLED_SELECTOR(testClassFunction);

- (void)testInstanceFunctionName:(NSString *)name
                             var:(NSString *)var  AE_JSHANDLED_SELECTOR(testInstanceFunction);

- (void)testInstanceFunctionName2:(NSString *)name
                             var2:(NSString *)var  AE_JSHANDLED_SELECTOR(testInstanceFunction2);

- (void)aesSetTitle:(id)body ;//AE_JSHANDLED_SELECTOR(aesSetTitle);

- (BOOL)addJSContexts:(NSSet<AEJSHandlerContext *> *)contexts;

@property(weak , nonatomic)AEHybridEngineManager *manager;

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(void (^)(id))callback;

@end



@interface AESJSCallBack : NSObject

@property (nonatomic, copy) NSString *succeedCallBack;

@property (nonatomic, copy) NSString *failureCallBack;

+ (instancetype)callBackWithRawData:(NSDictionary *)data;

@end
