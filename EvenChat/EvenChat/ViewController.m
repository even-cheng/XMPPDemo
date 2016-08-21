//
//  ViewController.m
//  EvenChat
//
//  Created by Even on 16/8/17.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "ViewController.h"

/*
 路人甲 : jia
 孔乙己 : kyj
 */

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //登录
    [[XMPPManager shareManager] loginWithJID:[XMPPJID jidWithUser:@"wang" domain:@"even.chat" resource:@"wang"] andPassword:@"123"];

    //注册
//    [[XMPPManager shareManager] registerWithJID:[XMPPJID jidWithUser:@"张三丰" domain:@"even.chat" resource:@"丰"] andPassword:@"feng"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
