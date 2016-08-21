//
//  XMPPRoomManager.h
//  EvenChat
//
//  Created by Even on 16/8/20.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPRoomManager : NSObject

// 多人聊天群组设置
@property (nonatomic, strong) XMPPMUC *xmppMuc;

@property (nonatomic, strong) NSMutableDictionary *dict;


/**
 *  单例
 *
 *  @return
 */
+ (instancetype)shareInstance;

/**
 *  加入聊天群的方法
 */

- (void)joinRoomWithJID:(XMPPJID *)roomJID andNickName:(NSString *)nickName;



@end
