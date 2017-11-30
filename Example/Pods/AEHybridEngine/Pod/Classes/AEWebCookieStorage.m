//
//  AEWebCookieStorage.m
//  Pods
//
//  Created by Altair on 11/08/2017.
//
//

#import "AEWebCookieStorage.h"

#define AEWEBCOOKIESTORAGE_SIGN (@"AEWebCookieStorageSign")


@interface NSString (AEWebCookieStorageTools)

- (NSString *)AEWebCookieStorage_URLencode;

- (NSString*)AEWebCookieStorage_URLDecoded;

@end


@implementation NSString (AEWebCookieStorageTools)

- (NSString *)AEWebCookieStorage_URLencode {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    size_t sourceLen = strlen((const char *)source);
    for (size_t i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

- (NSString*)AEWebCookieStorage_URLDecoded {
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                             (CFStringRef)self,
                                                                                                             CFSTR(""),
                                                                                                             kCFStringEncodingUTF8));
    return result;
}

@end


static inline NSString *AE_NSHTTPCookieHashKey(NSHTTPCookie *cookie) {
    return [NSString stringWithFormat:@"%@%@%@", cookie.name, cookie.domain, cookie.path];
}

@interface AEWebCookieStorage ()

@property (nonatomic, strong) NSMutableDictionary *cookieStorage;

+ (NSHTTPCookie *)signCookie:(NSHTTPCookie *)cookie;

@end

@implementation AEWebCookieStorage

+ (instancetype)sharedCookieStorage {
    static AEWebCookieStorage *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AEWebCookieStorage alloc] init];
        sharedInstance.cookieStorage = [[NSMutableDictionary alloc] init];
    });
    return sharedInstance;
}

- (NSArray<NSHTTPCookie *> *)cookies {
    return self.cookieStorage.allValues;
}

#pragma mark Private methods

+ (NSHTTPCookie *)signCookie:(NSHTTPCookie *)cookie {
    if (!cookie || ![cookie isKindOfClass:[NSHTTPCookie class]]) {
        return nil;
    }
    //给cookie打个标
    NSMutableDictionary *properties = [[cookie properties] mutableCopy];
    [properties setObject:AEWEBCOOKIESTORAGE_SIGN forKey:NSHTTPCookieComment];
    NSHTTPCookie *signedCookie = [NSHTTPCookie cookieWithProperties:properties];
    return signedCookie;
}

#pragma mark Public methods

- (void)setCookie:(NSHTTPCookie *)cookie {
    NSHTTPCookie *signedCookie = [AEWebCookieStorage signCookie:cookie];
    if (!signedCookie) {
        return;
    }
    //分别存到私有仓库和公共仓库
    [self.cookieStorage setObject:signedCookie forKey:AE_NSHTTPCookieHashKey(signedCookie)];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:signedCookie];
}

- (void)deleteCookie:(NSHTTPCookie *)cookie {
    NSHTTPCookie *signedCookie = [AEWebCookieStorage signCookie:cookie];
    if (!signedCookie) {
        return;
    }
    [self.cookieStorage removeObjectForKey:AE_NSHTTPCookieHashKey(signedCookie)];
}

- (void)removeAllCookies {
    //分别清理私有仓库和公共仓库中相关的cookie
    [self.cookieStorage removeAllObjects];
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.comment isEqualToString:AEWEBCOOKIESTORAGE_SIGN]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

- (NSURLRequest *)cookiedRequest:(NSURLRequest *)originalRequest {
    NSMutableURLRequest *request = [originalRequest mutableCopy];
    NSString *cookiesString = [self cookiesToString];
    [request setValue:cookiesString forHTTPHeaderField:@"Cookie"];
    
    return request;
}

- (NSString *)cookiesToString {
    NSArray *cookies = [self.cookies copy];
    if ([cookies count] == 0) {
        return nil;
    }
    NSMutableString *cookieString = [[NSMutableString alloc] init];
    for (NSHTTPCookie *cookie in cookies) {
        NSString *name = cookie.name;
        NSString *value = cookie.value;
        if (name.length > 0 && value.length > 0) {
            [cookieString appendFormat:@"%@=%@;", name, value];
        }
    }
    
    return [cookieString copy];
}

@end
