//
//  XMPPRoomManager.m
//  EvenChat
//
//  Created by Even on 16/8/20.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "XMPPRoomManager.h"

@interface XMPPRoomManager ()<XMPPMUCDelegate,XMPPRoomDelegate>

@end

@implementation XMPPRoomManager

/**
 *  单例
 *
 *  @return
 */
+ (instancetype)shareInstance;
{
    static XMPPRoomManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [XMPPRoomManager new];
        
        [instance setupModule];
    });
    return instance;
}

// 开启功能模块的方法
- (void)setupModule
{
    [self.xmppMuc addDelegate:self delegateQueue:dispatch_get_main_queue()];
    // 激活
    [self.xmppMuc activate:[XMPPManager shareManager].xmppStream];
}

/**
 *  加入聊天群
 *
 *  @param roomJID  jid
 *  @param nickName 昵称
 */
- (void)joinRoomWithJID:(XMPPJID *)roomJID andNickName:(NSString *)nickName;
{
    XMPPRoom *xmppRoom = self.dict[roomJID];
    if (xmppRoom == nil) {
        // 创建一个房间
        xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPRoomCoreDataStorage sharedInstance] jid:roomJID dispatchQueue:dispatch_get_main_queue()];
        
        // 添加代理
        [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 激活
        [xmppRoom activate:[XMPPManager shareManager].xmppStream];
        
        [self.dict setValue:xmppRoom forKey:roomJID.bare];
    }
    
    // 加入聊天群里面去
    //  <history maxstanzas='100'/>
    DDXMLElement *history = [DDXMLElement elementWithName:@"history"];
    [history addAttributeWithName:@"maxstanzas" intValue:1];
    
    [xmppRoom joinRoomUsingNickname:nickName history:history];
    
}

- (void)xmppRoomDidCreate:(XMPPRoom *)sender;
{
    NSLog(@"房间已经创建");
    
    [sender fetchConfigurationForm];
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(DDXMLElement *)configForm
{
    [sender configureRoomUsingOptions:nil];
}




- (XMPPMUC *)xmppMuc
{
    if (_xmppMuc == nil) {
        _xmppMuc = [[XMPPMUC alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppMuc;
}

- (NSMutableDictionary *)dict
{
    if (_dict == nil) {
        _dict = [NSMutableDictionary dictionary];
    }
    return _dict;
}

@end
