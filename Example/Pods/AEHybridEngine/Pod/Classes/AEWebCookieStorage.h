//
//  AEWebCookieStorage.h
//  Pods
//
//  Created by Altair on 11/08/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AEWebCookieStorage : NSObject

@property (nullable , readonly, copy) NSArray<NSHTTPCookie *> *cookies;

+ (instancetype)sharedCookieStorage;

- (void)setCookie:(NSHTTPCookie *)cookie;

- (void)deleteCookie:(NSHTTPCookie *)cookie;

- (void)removeAllCookies;

- (NSURLRequest *)cookiedRequest:(NSURLRequest *)originalRequest;

- (NSString *)cookiesToString;

@end

NS_ASSUME_NONNULL_END
