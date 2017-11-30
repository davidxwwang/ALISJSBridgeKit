//
//  AEJavaScriptHandler.m
//  TestWebViewContainer
//
//  Created by Altair on 12/06/2017.
//  Copyright © 2017 Alisports. All rights reserved.
//

#import "AEJavaScriptHandler.h"
#import "AEHybridEngine.h"

static NSHashTable *AEJavaScriptHandler_JSHandlerContainer = nil;

static AEJavaScriptHandler *_rootJSHandler = nil;

@interface AEJavaScriptHandler ()
    
@property (nonatomic, assign) BOOL hasChanged;

- (void)autoFullfill;

@end

@implementation AEJavaScriptHandler

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        self.autoFillable = YES;
        [self autoFullfill];
        //将自己添加到弱引用的HashTable
        if (!AEJavaScriptHandler_JSHandlerContainer) {
            AEJavaScriptHandler_JSHandlerContainer = [NSHashTable weakObjectsHashTable];
        }
        [AEJavaScriptHandler_JSHandlerContainer addObject:self];
    }
    return self;
}
    
- (instancetype)initWithPerformer:(id)performer {
    self = [self init];
    if (self) {
        self.performer = performer;
    }
    return self;
}
    
+ (instancetype)handlerWithPerformer:(id)performer {
    AEJavaScriptHandler *handler = [[AEJavaScriptHandler alloc] initWithPerformer:performer];
    return handler;
}

#pragma mark Setter & Getter

- (void)setJsContexts:(NSSet<AEJSHandlerContext *> *)jsContexts {
    @synchronized (self) {
        _jsContexts = [[AEJavaScriptHandler autoClearForContexts:jsContexts] copy];
        if (self.HandledContextsChanged) {
            __weak typeof(self) weakSelf = self;
            self.HandledContextsChanged(weakSelf);
        }
    }
}

#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self responseToJSCallWithScriptMessage:message];
}

#pragma mark Private methods
    
- (void)setAutoFillable:(BOOL)autoFillable {
    _autoFillable = autoFillable;
    if (!autoFillable && !self.hasChanged) {
        self.jsContexts = nil;
    }
}

- (void)autoFullfill {
    //从根JSHandler处copy一份JSContexts
    if (_rootJSHandler) {
        self.jsContexts = _rootJSHandler.jsContexts;
    } else {
        //没有合适的活动中JSHandler，则主动将类方法注册给自己
        [AEHybridLauncher registerNativeMethodsOfType:AEMethodTypeClass forPerformer:nil toJavaScriptHandler:self];
    }
}
    
+ (NSSet<AEJSHandlerContext *> *)autoClearForContexts:(NSSet<AEJSHandlerContext *> *)contexts {
    NSMutableSet *tempSet = [contexts mutableCopy];
    for (AEJSHandlerContext *cont in contexts) {
        if ([cont isKindOfClass:[AEJSHandlerPerformerContext class]] && !((AEJSHandlerPerformerContext *)cont).performer) {
            [tempSet removeObject:cont];
        } else if ([cont isKindOfClass:[AEJSHandlerBlockContext class]] && !((AEJSHandlerBlockContext *)cont).JSCallback) {
            [tempSet removeObject:cont];
        }
    }
    return tempSet;
}

#pragma mark Public methods

- (BOOL)addJSContexts:(NSSet<AEJSHandlerContext *> *)contexts {
    if (![contexts isKindOfClass:[NSSet class]] || [contexts count] == 0) {
        return NO;
    }
    @synchronized (self) {
        self.hasChanged = YES;
        NSUInteger addCount = 0;
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        if (!tempSet) {
            tempSet = [[NSMutableSet alloc] init];
        }
        for (AEJSHandlerContext *cont in contexts) {
            if ([cont isValid]) {
                BOOL existing = NO;
                for (AEJSHandlerContext *selfContext in self.jsContexts) {
                    if ([cont isEqualTo:selfContext]) {
                        existing = YES;
                    }
                }
                if (!existing) {
                    //未找到相同的，则添加
                    [tempSet addObject:cont];
                    addCount ++;
                }
            }
        }
        
        if (addCount > 0) {
            self.jsContexts = tempSet;
            return YES;
        }
    }
    
    return NO;
}

- (void)removeJSContextsForPerformer:(id)performer {
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *cont in self.jsContexts) {
            if ([cont isKindOfClass:[AEJSHandlerPerformerContext class]] && ((AEJSHandlerPerformerContext *)cont).performer == performer) {
                [tempSet removeObject:cont];
            }
        }
        self.jsContexts = tempSet;
    }
}

- (void)removeJSContextsWithSEL:(SEL)selector {
    if (!selector) {
        return;
    }
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *cont in self.jsContexts) {
            if ([cont isKindOfClass:[AEJSHandlerPerformerContext class]] && [NSStringFromSelector(((AEJSHandlerPerformerContext *)cont).selector) isEqualToString:NSStringFromSelector(selector)]) {
                [tempSet removeObject:cont];
            }
        }
        self.jsContexts = tempSet;
    }
}

- (void)removeJSContextsWithAliasName:(NSString *)name {
    if (!name || ![name isKindOfClass:[NSString class]]) {
        return;
    }
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *cont in self.jsContexts) {
            if ([cont.aliasName isEqualToString:name]) {
                [tempSet removeObject:cont];
            }
        }
        self.jsContexts = tempSet;
    }
}

- (BOOL)responseToCallWithJSContext:(AEJSHandlerContext *)context {
    if ([context isKindOfClass:[AEJSHandlerPerformerContext class]]) {
        return [self responseToCallWithJSPerformerContext:(AEJSHandlerPerformerContext *)context];
    }
    if ([context isKindOfClass:[AEJSHandlerBlockContext class]]) {
        return [self responseToCallWithJSBlockContext:(AEJSHandlerBlockContext *)context];
    }
    return NO;
}

- (BOOL)responseToCallWithJSPerformerContext:(AEJSHandlerPerformerContext *)context {
    if (!context.performer || !context.selector) {
        return NO;
    }
    NSString *selectorString = NSStringFromSelector(context.selector);
    if ([selectorString length] > 1) {
        //针对"+"和"-"方法，做一下容错处理，方式方法名中带有类型符号
        NSString *methodTypeString = [selectorString substringToIndex:1];
        if ([methodTypeString isEqualToString:@"+"] || [methodTypeString isEqualToString:@"-"]) {
            selectorString = [selectorString substringFromIndex:1];
        }
    }
    SEL performSelector = NSSelectorFromString(selectorString);
    if ([context.performer respondsToSelector:performSelector]) {
        [context.performer performSelector:performSelector withObject:context.args afterDelay:0];
        return YES;
    }
    return NO;
}

- (BOOL)responseToCallWithJSBlockContext:(AEJSHandlerBlockContext *)context {
    if (context.JSCallback) {
        context.JSCallback(context);
        return YES;
    }
    return NO;
}

- (BOOL)responseToJSCallWithScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"JS 调用了 %@ 方法，传回参数 %@", message.name, message.body);
    AEJSHandlerContext *fullFillContext = nil;
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *context in self.jsContexts) {
            if ([context.aliasName isEqualToString:message.name] ||([context isKindOfClass:[AEJSHandlerPerformerContext class]] && [message.name isEqualToString:NSStringFromSelector(((AEJSHandlerPerformerContext *)context).selector)])) {
                fullFillContext = [context copy];
                fullFillContext.args = message.body;
                if ([context isKindOfClass:[AEJSHandlerPerformerContext class]] && ((AEJSHandlerPerformerContext *)context).performer) {
                    //如果执行者未释放，则选定
                    break;
                } else if ([context isKindOfClass:[AEJSHandlerBlockContext class]] && ((AEJSHandlerBlockContext *)context).JSCallback) {
                    //如果执行者未释放，则选定
                    break;
                }
                else {
                    //如果执行者已释放，则删除该context，并继续遍历
                    [tempSet removeObject:context];
                    continue;
                }
            }
        }
        if ([tempSet count] != [self.jsContexts count]) {
            //数量不同，说明变动过了，则重新赋值
            self.jsContexts = tempSet;
        }
    }
    return [self responseToCallWithJSContext:fullFillContext];
}

+ (NSArray<AEJavaScriptHandler *> * _Nullable __autoreleasing)activeHandlers {
    if (!AEJavaScriptHandler_JSHandlerContainer) {
        AEJavaScriptHandler_JSHandlerContainer = [NSHashTable weakObjectsHashTable];
    }
    if (!_rootJSHandler) {
        //如果没有活动的Handler，则创建一个根handler，以便保存设置的contexts
        _rootJSHandler = [[AEJavaScriptHandler alloc] init];
        [AEJavaScriptHandler_JSHandlerContainer addObject:_rootJSHandler];
    }
    return [AEJavaScriptHandler_JSHandlerContainer allObjects];
}

@end




@implementation AEJSHandlerContext

- (void)setAliasName:(NSString *)aliasName {
    if ([aliasName isKindOfClass:[NSString class]]) {
        _aliasName = aliasName;
    }
}

- (BOOL)isEqualTo:(AEJSHandlerContext *)context {
    BOOL isEq = NO;
    if ([self.aliasName isEqualToString:context.aliasName]) {
        isEq = YES;
    }
    return isEq;
}

- (BOOL)isValid {
    if ([self.aliasName length] > 0) {
        return YES;
    }
    return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    AEJSHandlerContext *context = [[AEJSHandlerContext allocWithZone:zone] init];
    context.args = self.args;
    context.aliasName = self.aliasName;
    return context;
}

@end

@implementation AEJSHandlerPerformerContext

+ (instancetype)contextWithPerformer:(id)performer selector:(SEL)selector aliasName:(NSString *)aliasName {
    if (!performer || !selector) {
        return nil;
    }
    AEJSHandlerPerformerContext *context = [[AEJSHandlerPerformerContext alloc] init];
    context.performer = performer;
    context.selector = selector;
    context.aliasName = aliasName;
    return context;
}

- (BOOL)isEqualTo:(AEJSHandlerContext *)context {
    BOOL isEq = NO;
    if ([context isKindOfClass:[AEJSHandlerPerformerContext class]] && self.performer == ((AEJSHandlerPerformerContext *)context).performer &&
        [NSStringFromSelector(self.selector) isEqualToString:NSStringFromSelector(((AEJSHandlerPerformerContext *)context).selector)] &&
        [self.aliasName isEqualToString:((AEJSHandlerPerformerContext *)context).aliasName]) {
        isEq = YES;
    }
    return isEq;
}

- (BOOL)isValid {
    if (self.performer && ([self.aliasName length] > 0 || [NSStringFromSelector(self.selector) length] > 0)) {
        return YES;
    }
    return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    AEJSHandlerPerformerContext *context = [[AEJSHandlerPerformerContext allocWithZone:zone] init];
    context.args = self.args;
    context.aliasName = self.aliasName;
    context.performer = self.performer;
    context.selector = self.selector;
    return context;
}

@end

@implementation AEJSHandlerBlockContext

+ (instancetype)contextWithAliasName:(NSString *)aliasName jsCallback:(void (^)(AEJSHandlerBlockContext * _Nonnull))callback {
    if ([aliasName length] == 0 || !callback) {
        return nil;
    }
    AEJSHandlerBlockContext *context = [[AEJSHandlerBlockContext alloc] init];
    context.aliasName = aliasName;
    context.JSCallback = callback;
    return context;
}

- (BOOL)isEqualTo:(AEJSHandlerContext *)context {
    BOOL isEq = NO;
    if ([context isKindOfClass:[AEJSHandlerBlockContext class]] && self.JSCallback == ((AEJSHandlerBlockContext *)context).JSCallback && [self.aliasName isEqualToString:((AEJSHandlerBlockContext *)context).aliasName]) {
        isEq = YES;
    }
    return isEq;
}

- (BOOL)isValid {
    if (self.JSCallback && [self.aliasName length] > 0) {
        return YES;
    }
    return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    AEJSHandlerBlockContext *context = [[AEJSHandlerBlockContext allocWithZone:zone] init];
    context.args = self.args;
    context.aliasName = self.aliasName;
    context.JSCallback = self.JSCallback;
    return context;
}

@end


@implementation WeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end
