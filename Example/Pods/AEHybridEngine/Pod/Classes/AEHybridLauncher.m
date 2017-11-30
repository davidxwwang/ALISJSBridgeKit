//
//  AEHybridLauncher.m
//  Pods
//
//  Created by Altair on 02/08/2017.
//
//

#import "AEHybridLauncher.h"
#import <objc/runtime.h>

#define AE_JSMETHOD_INFOKEY    (@"AEJavaScriptHandledMethods")
#define AE_JSMETHOD_SEPARATOR (@"|")

typedef enum {
    AEHybridMethodTypeInstance,
    AEHybridMethodTypeClass
}AEHybridMethodType;

static inline void AEHybridLauncher_ReplaceSelectorWithSelector(Class aCls, SEL selector, SEL replacementSelector, AEHybridMethodType methodType) {
    
    Method replacementSelectorMethod = (methodType == AEHybridMethodTypeClass
                                        ? class_getClassMethod(aCls, replacementSelector)
                                        : class_getInstanceMethod(aCls, replacementSelector));
    
    Class classEntityToEdit = aCls;
    if (methodType == AEHybridMethodTypeClass) {
        // Get meta-class
        classEntityToEdit = object_getClass(aCls);
    }
    class_replaceMethod(classEntityToEdit,
                        selector,
                        method_getImplementation(replacementSelectorMethod),
                        method_getTypeEncoding(replacementSelectorMethod));
}

static BOOL AEHrybridEngineHasLaunched = NO;

@interface AEHybridLauncher ()

+ (void)prepareForPerformerInstance;

+ (void)resetForPerformerInstance;

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)builtNativeMethodsInfo;

+ (NSSet<NSString *> *)instanceTypedPerformerClasses;

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfClassMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info;

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfInstanceMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info;

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfAllKindsOfMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info;

@end

@implementation AEHybridLauncher

#pragma mark Private methods

+ (void)prepareForPerformerInstance {
    NSSet<NSString *> *performerClasses = [AEHybridLauncher instanceTypedPerformerClasses];
    for (NSString *className in performerClasses) {
        Class toClass = objc_getClass([className UTF8String]);
        AEHybridLauncher_ReplaceSelectorWithSelector(toClass, @selector(AEHybridHook_original_alloc), @selector(alloc), AEHybridMethodTypeClass);
        AEHybridLauncher_ReplaceSelectorWithSelector(toClass, @selector(alloc), @selector(AEHybridHook_replaced_alloc), AEHybridMethodTypeClass);
    }
}

+ (void)resetForPerformerInstance {
    NSSet<NSString *> *performerClasses = [AEHybridLauncher instanceTypedPerformerClasses];
    for (NSString *className in performerClasses) {
        Class toClass = objc_getClass([className UTF8String]);
        AEHybridLauncher_ReplaceSelectorWithSelector(toClass, @selector(alloc), @selector(AEHybridHook_original_alloc), AEHybridMethodTypeClass);
    }
}

+ (NSSet<NSString *> *)instanceTypedPerformerClasses {
    static NSSet<NSString *> *performerClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSString *, NSArray<NSString *> *> *info = [AEHybridLauncher builtNativeMethodsInfo];
        //遍历所有的Native类
        NSMutableSet *tempSet = [[NSMutableSet alloc] init];
        [info enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
            //方法列表
            for (NSString *methodName in obj) {
                if ([methodName hasPrefix:@"-"]) {
                    [tempSet addObject:key];
                }
            }
        }];
        performerClasses = [tempSet copy];
    });
    return performerClasses;
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)builtNativeMethodsInfo {
    static NSDictionary<NSString *, NSArray<NSString *> *> *nativeMethodsInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nativeMethodsInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:AE_JSMETHOD_INFOKEY];
    });
    return nativeMethodsInfo;
}

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfClassMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *,NSArray<NSString *> *> *)info {
    if (!info || ![info isKindOfClass:[NSDictionary class]] || [info count] == 0) {
        return nil;
    }
    NSMutableSet *set = [[NSMutableSet alloc] init];
    NSString *performerClassName = performer ? NSStringFromClass([performer class]) : nil;
    if (performerClassName) {
        //指定了方法执行者，则只遍历方法执行者类
        NSArray<NSString *> *methods = [info objectForKey:performerClassName];
        for (NSString *methodName in methods) {
            if ([methodName hasPrefix:@"+"]) {
                //类方法（静态）
                NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                AEJSHandlerPerformerContext *context = [AEJSHandlerPerformerContext contextWithPerformer:[performer class] selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                if (context) {
                    [set addObject:context];
                }
            }
        }
    } else {
        //未指定方法执行者，则遍历所有的Native类
        [info enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
            //没有指定的执行者，则将所有的类方法找出
            //类
            Class handledClass = NSClassFromString(key);
            //方法列表
            for (NSString *methodName in obj) {
                if ([methodName hasPrefix:@"+"]) {
                    //类方法（静态）
                    NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                    //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                    
                    AEJSHandlerPerformerContext *context = [AEJSHandlerPerformerContext contextWithPerformer:handledClass selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                    if (context) {
                        [set addObject:context];
                    }
                }
            }
        }];
    }
    return set;
}

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfInstanceMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info {
    if (!info || ![info isKindOfClass:[NSDictionary class]] || [info count] == 0 || !performer) {
        return nil;
    }
    //执行者的类名
    NSString *performerClassName = NSStringFromClass([performer class]);
    NSMutableSet *set = [[NSMutableSet alloc] init];
    //遍历所有的Native类
    [info enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        //类名
        if ([performerClassName isEqualToString:key]) {
            //方法列表
            for (NSString *methodName in obj) {
                if ([methodName hasPrefix:@"-"]) {
                    //实例方法
                    NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                    //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                    AEJSHandlerPerformerContext *context = [AEJSHandlerPerformerContext contextWithPerformer:performer selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                    if (context) {
                        [set addObject:context];
                    }
                }
            }
            *stop = YES;
        }
    }];
    return set;
}

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfAllKindsOfMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info {
    if (!info || ![info isKindOfClass:[NSDictionary class]] || [info count] == 0) {
        return nil;
    }
    //执行者的类名
    NSMutableSet *set = [[NSMutableSet alloc] init];
    NSString *performerClassName = performer ? NSStringFromClass([performer class]) : nil;
    if (performerClassName) {
        //指定了方法执行者，则只遍历方法执行者类
        NSArray<NSString *> *methods = [info objectForKey:performerClassName];
        for (NSString *methodName in methods) {
            if ([methodName hasPrefix:@"+"]) {
                //类方法（静态）
                NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                AEJSHandlerPerformerContext *context = [AEJSHandlerPerformerContext contextWithPerformer:[performer class] selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                if (context) {
                    [set addObject:context];
                }
            } else if ([methodName hasPrefix:@"-"]) {
                //实例方法
                NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                AEJSHandlerPerformerContext *context = [AEJSHandlerPerformerContext contextWithPerformer:performer selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                if (context) {
                    [set addObject:context];
                }
            }
        }
    } else {
        //未指定方法执行者，则与获取所有类方法的相同
        [AEHybridLauncher jsContextsOfClassMethodsForPerformer:nil fromNativeMethodsInfo:info];
    }
    return set;
}

#pragma mark Public methods

+ (void)launch {
    if (AEHrybridEngineHasLaunched) {
        return;
    }
    AEHrybridEngineHasLaunched = YES;
    [AEHybridLauncher prepareForPerformerInstance];
}

+ (void)extinguish {
    if (!AEHrybridEngineHasLaunched) {
        return;
    }
    [AEHybridLauncher resetForPerformerInstance];
    AEHrybridEngineHasLaunched = NO;
}

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfType:(AEMethodType)type forPerformer:(id _Nullable)performer {
    NSSet *contexts = nil;
    switch (type) {
        case AEMethodTypeClass:
            contexts = [AEHybridLauncher jsContextsOfClassMethodsForPerformer:performer fromNativeMethodsInfo:[AEHybridLauncher builtNativeMethodsInfo]];
            break;
        case AEMethodTypeInstance:
            contexts = [AEHybridLauncher jsContextsOfInstanceMethodsForPerformer:performer fromNativeMethodsInfo:[AEHybridLauncher builtNativeMethodsInfo]];
            break;
        case AEMethodTypeAll:
            contexts = [AEHybridLauncher jsContextsOfAllKindsOfMethodsForPerformer:performer fromNativeMethodsInfo:[AEHybridLauncher builtNativeMethodsInfo]];
            break;
        default:
            break;
    }
    return contexts;
}

+ (void)registerNativeMethodsOfType:(AEMethodType)type forPerformer:(id _Nullable)performer {
    NSArray<AEJavaScriptHandler *> *activeHandlers = [AEJavaScriptHandler activeHandlers];
    for (AEJavaScriptHandler *handler in activeHandlers) {
        [AEHybridLauncher registerNativeMethodsOfType:type forPerformer:performer toJavaScriptHandler:handler];
    }
}

+ (void)registerNativeMethodsOfType:(AEMethodType)type forPerformer:(id _Nullable)performer toJavaScriptHandler:(nonnull AEJavaScriptHandler *)handler {
    if (!handler.autoFillable) {
        return;
    }
    NSSet *contexts = [AEHybridLauncher jsContextsOfType:type forPerformer:performer];
    //更新JSContexts
    [handler addJSContexts:contexts];
}
    
+ (void)unregisterNativeMethodsWithPerformer:(id)performer {
    NSArray<AEJavaScriptHandler *> *activeHandlers = [AEJavaScriptHandler activeHandlers];
    for (AEJavaScriptHandler *handler in activeHandlers) {
        [AEHybridLauncher unregisterNativeMethodsWithPerformer:performer fromJavaScriptHandler:handler];
    }
}
    
+ (void)unregisterNativeMethodsWithPerformer:(id)performer fromJavaScriptHandler:(AEJavaScriptHandler *)handler {
    if (!performer || !handler) {
        return;
    }
    [handler removeJSContextsForPerformer:performer];
    if (handler.performer == performer) {
        handler.performer = nil;
    }
}

@end



@implementation NSObject (AEHybridHook)

+ (instancetype)AEHybridHook_original_alloc {
    return nil;
}

+ (instancetype)AEHybridHook_replaced_alloc {
    id instance = [self AEHybridHook_original_alloc];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [AEHybridLauncher registerNativeMethodsOfType:AEMethodTypeInstance forPerformer:instance];
    });
    NSLog(@"An AEHybridEngine hooked class %@ has been allocated.", self);
    return instance;
}

@end



