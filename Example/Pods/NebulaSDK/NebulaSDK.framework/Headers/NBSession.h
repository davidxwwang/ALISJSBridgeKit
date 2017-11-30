//
//  NBSession.h
//  NBService
//
//  Created by chenwenhong on 15/8/25.
//  Copyright (c) 2015年 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBSessionContext.h"

@class NBSessionDelegate;

@interface NBSession : NSObject

@property(nonatomic, strong) NBSessionDelegate          *delegate;
@property(nonatomic, readonly, strong) NBSessionContext *context;

- (void)loadDataSourceForApps:(NSArray *)arrApps;

@end
