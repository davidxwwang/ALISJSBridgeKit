//
//  NSData+RSA.h
//  APOpenSSL
//
//  Created by tashigaofei on 14-8-12.
//  Copyright (c) 2014年 Alipay. All rights reserved.
//



@interface NSData (RSA)

-(NSData *) dataByRSAEncryptedWithPublicKey:(NSString *) key;
-(NSData *) dataByRSADecryptedWithPrivateKey:(NSString *) key;

@end
