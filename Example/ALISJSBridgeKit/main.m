//
//  main.m
//  ALISJSBridgeKit
//
//  Created by xwwang_0102@qq.com on 11/21/2017.
//  Copyright (c) 2017 xwwang_0102@qq.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALISAppDelegate.h"
#import <dirent.h>
#import <dlfcn.h>

FILE *fopen$UNIX2003( const char *filename, const char *mode )
{
    return fopen(filename, mode);
}

size_t fwrite$UNIX2003( const void *a, size_t b, size_t c, FILE *d )
{
    return fwrite(a, b, c, d);
}

char *strerror$UNIX2003( int errnum )
{
    return strerror(errnum);
}

DIR *opendir$INODE64(const char * a)
{
    return opendir(a);
}

struct dirent *readdir$INODE64(DIR *dir)
{
    return readdir(dir);
}
#import "ALISAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ALISAppDelegate class]));
    }
}
