//
//  XMPPManager.h
//  EvenChat
//
//  Created by Even on 16/8/17.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPManager : NSObject


//密码
@property (nonatomic, copy) NSString *password;
//判断是否登录
@property (nonatomic, assign) BOOL isLogin;


/**
 *  XML流
 */
@property (strong,nonatomic) XMPPStream* xmppStream;

/**
 *  心跳检测模块
 */
@property (strong,nonatomic) XMPPAutoPing* xmppAutoPing;

/**
 *  自动重连模块
 */
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;

/**
 *  联系人模块
 */
@property (nonatomic, strong) XMPPRoster *xmppRoster;

/**
 *  消息模块
 */
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;

// 电子名片模块
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCard;

// 照片模块
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppAvatar;

// 文件的接收
@property (nonatomic, strong) XMPPIncomingFileTransfer *xmppIncomingFile;

// 文件的发送
@property (nonatomic, strong) XMPPOutgoingFileTransfer *xmppOutgoingFile;


//管理类
+(instancetype)shareManager;


/**
 *  注册
 *
 *  @param jid      名称
 *  @param password 密码
 */
-(void)registerWithJID:(XMPPJID*)jid andPassword:(NSString*)password;


/**
 *  登录
 *
 *  @param jid      名称
 *  @param password 密码
 */
-(void)loginWithJID:(XMPPJID*)jid andPassword:(NSString*)password;





@end
