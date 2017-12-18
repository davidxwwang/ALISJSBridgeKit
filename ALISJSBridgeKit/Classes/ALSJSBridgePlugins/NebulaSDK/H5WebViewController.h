//
//  H5WebViewController.h
//  NebulaDemo
//
//  Created by Glance on 16/12/14.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef ALS_HAS_NebulaSDK 

@interface H5WebViewController : UIViewController

- (IBAction)btnBackItemClicked:(id)sender;

- (IBAction)btnRightItemClicked:(id)sender;

@end

#endif 
