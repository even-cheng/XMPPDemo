//
//  XMPPManager.m
//  EvenChat
//
//  Created by Even on 16/8/17.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "XMPPManager.h"

@interface XMPPManager ()<XMPPStreamDelegate,XMPPRosterDelegate,XMPPAutoPingDelegate,XMPPIncomingFileTransferDelegate>

@property (nonatomic, strong) NSMutableDictionary *dict;

@end


@implementation XMPPManager

+(instancetype)shareManager;
{
    static XMPPManager* _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _instance = [[XMPPManager alloc]init];
        
        //开启模块
        [_instance setupModule];
    });
    
    return _instance;
}



#pragma mark - 开启模块
-(void)setupModule
{

    //心跳检测模块
    self.xmppAutoPing.pingInterval = 20.0; //发包间隔
    self.xmppAutoPing.pingTimeout = 20;//超时时长
    self.xmppAutoPing.respondsToQueries = YES;//是否响应服务器发来的心跳检测包
    [self.xmppAutoPing addDelegate:self delegateQueue:dispatch_get_main_queue()];//代理检测
    [self.xmppAutoPing activate:self.xmppStream];//激活当前模块
    
    //自动重连模块
    [self.xmppReconnect activate:self.xmppStream];//激活模块
    
    //联系人模块
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = NO;//自动接收订阅请求
    self.xmppRoster.autoFetchRoster = YES;//从服务器获取联系人列表(只会调用一次)
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];//添加代理
    [self.xmppRoster activate:self.xmppStream];//激活模块
    
    //消息模块
    [self.xmppMessageArchiving activate:self.xmppStream];//激活模块
    
    // 电子名片模块
    [self.xmppvCard activate:self.xmppStream];
    
    // 照片
    [self.xmppAvatar activate:self.xmppStream];
    
    // 文件的收发
    // 是否自动接收文件
    self.xmppIncomingFile.autoAcceptFileTransfers = NO;
    
    [self.xmppIncomingFile addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [self.xmppIncomingFile activate:self.xmppStream];
    
    [self.xmppOutgoingFile activate:self.xmppStream];
}


#pragma mark - 注册和登录
-(void)registerWithJID:(XMPPJID*)jid andPassword:(NSString*)password;
{
    self.xmppStream.myJID = jid;
    self.xmppStream.hostName = kHostName;
    self.xmppStream.hostPort = kHostPort;
    self.password = password;
    
    //连接
    BOOL result = [self.xmppStream connectWithTimeout:-1 error:nil];
    if (!result) {
        NSLog(@"连接失败");
    }
    
}


-(void)loginWithJID:(XMPPJID*)jid andPassword:(NSString*)password;
{
    self.xmppStream.myJID = jid;
    self.xmppStream.hostName = kHostName;
    self.xmppStream.hostPort = kHostPort;
    self.password = password;
    self.isLogin = YES;

    //连接
    BOOL result = [self.xmppStream connectWithTimeout:-1 error:nil];
    if (!result) {
        NSLog(@"连接失败");
    }

}

#pragma mark - XMPPIncomingFileTransferDelegate
// offer: 请求
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
               didReceiveSIOffer:(XMPPIQ *)offer;
{
    NSString *fileSender = [offer attributeStringValueForName:@"from"];
    DDXMLElement *siElement = offer.children.lastObject;
    for (DDXMLElement *file in siElement.children) {
        
        if ([file.name isEqualToString:@"file"]) {
            
            NSString *name = [file attributeStringValueForName:@"name"];
            
            // 保存
            [self.dict setValue:fileSender forKey:name];
        }
    }
    
    NSLog(@"接收到一个文件请求时调用");
    
    [self.xmppIncomingFile acceptSIOffer:offer];
}

/**
 *  成功接收发送过来的文件后调用的方法
 *
 *  @param sender
 *  @param data   发送的文件数据
 *  @param name   发送的文件名
 */
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
              didSucceedWithData:(NSData *)data
                           named:(NSString *)name;
{
    NSLog(@"接收到文件后调用");
    NSString *fileSender = self.dict[name];
    
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat"];
    
    NSRange range = [name rangeOfString:@"."];
    
    NSString *fileStr = [name substringFromIndex:range.location + 1];
    int fileType;
    if ([fileStr isEqualToString:@"png"] || [fileStr isEqualToString:@"jpg"]) {
        // 都是图片
        fileType = XMPP_TRANSFER_IMG;
        
    } else {
        // 其他类型
        fileType = XMPP_TRANSFER_FILE;
    }
    
    DDXMLElement *subjectElement = [DDXMLElement elementWithName:@"subject" stringValue:[NSString stringWithFormat:@"%d",fileType]];
    
    [message addChild:subjectElement];
    
    
    // 把fileSender添加一下属性
    [message addAttributeWithName:@"from" stringValue:fileSender];
    
    [message addBody:name];
    
    [[XMPPMessageArchivingCoreDataStorage sharedInstance] archiveMessage:message outgoing:NO xmppStream:self.xmppStream];
    
    
    
    //保存文件
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject,name];
    
    NSLog(@"%@",filePath);
    
    [data writeToFile:filePath atomically:YES];
}



#pragma mark - XMPPRosterDelegate
//接收到订阅请求
-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ask = 'subscribe'"];
    [fetchRequest setPredicate:predicate];
    
    
    //区分是对方加我还是我加对方为好友
    NSArray* fetchObjects = [[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:nil];

    for (XMPPUserCoreDataStorageObject* contact in fetchObjects) {
        
        //我加别人
        if ([contact.jidStr isEqualToString:presence.from.bare]) {
            
            //直接同意
            [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
            
            //弹窗
            UIAlertController* alterVC = [UIAlertController alertControllerWithTitle:@"添加好友" message:[NSString stringWithFormat:@"%@接受我的好友请求",contact.jidStr]  preferredStyle:UIAlertControllerStyleActionSheet];
            //展示弹窗
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alterVC animated:YES completion:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [alterVC dismissViewControllerAnimated:YES completion:nil];
            });
            
        }
        
        return;
    }
    
    //别人加我
    UIAlertController* alterVC = [UIAlertController alertControllerWithTitle:@"添加好友" message:[NSString stringWithFormat:@"%@想添加你为好友",presence.from.bare] preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* action1 = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       
        //接收请求
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
    }];
    UIAlertAction* action2 = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        //接收请求
        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:presence.from];
    }];
    
    [alterVC addAction:action1];
    [alterVC addAction:action2];
    
    //弹窗
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alterVC animated:YES completion:nil];
    
}


#pragma mark -  XMPPAutoPingDelegate
//接收到发来的心跳检测
-(void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender{

    NSLog(@"连接存在");
}

//检测到超时
-(void)xmppAutoPingDidTimeout:(XMPPAutoPing *)sender{

    NSLog(@"连接超时");
}


#pragma mark - XMPPStreamDelegate
//连接成功
-(void)xmppStreamDidConnect:(XMPPStream *)sender{

    NSLog(@"连接成功");
    
    if (self.isLogin)
    {
        //登录
        BOOL result = [self.xmppStream authenticateWithPassword:self.password error:nil];
        if (!result) {
            NSLog(@"登录失败");
        }
        
    } else {
    
        //注册
        BOOL result = [self.xmppStream registerWithPassword:self.password error:nil];
        if (!result) {
            NSLog(@"注册失败");
        }
    }
    
}

//注册成功
-(void)xmppStreamDidRegister:(XMPPStream *)sender{

     NSLog(@"注册成功");
}

//登录成功
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{

     NSLog(@"登录成功");

    //设置在线状态
    XMPPPresence* presence = [XMPPPresence presence];
    //请勿打扰状态
    DDXMLElement* showElement = [DDXMLElement elementWithName:@"show" stringValue:@"dnd"];
    [presence addChild:showElement];
    
    //设置签名
    DDXMLElement* statusElement = [DDXMLElement elementWithName:@"status" stringValue:@"正在忙呢~"];
    [presence addChild:statusElement];
    
    //展示状态
    [self.xmppStream sendElement:presence];
    
    //登录成功之后跳转到主控制器
    [UIApplication sharedApplication].keyWindow.rootViewController = [[UIStoryboard storyboardWithName:@"Root" bundle:nil] instantiateInitialViewController];
}



#pragma mark - 懒加载
-(XMPPStream *)xmppStream{

    if (!_xmppStream) {
        _xmppStream = [[XMPPStream alloc]init];
        //设置代理(多播代理)
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppStream;
}

-(XMPPAutoPing *)xmppAutoPing{

    if (!_xmppAutoPing) {
        _xmppAutoPing = [[XMPPAutoPing alloc]initWithDispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppAutoPing;
}

-(XMPPReconnect *)xmppReconnect{
    
    if (!_xmppReconnect) {
        _xmppReconnect = [[XMPPReconnect alloc]initWithDispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppReconnect;
}

-(XMPPRoster *)xmppRoster{

    if (!_xmppRoster) {//使用coreData存储
        _xmppRoster = [[XMPPRoster alloc]initWithRosterStorage:[XMPPRosterCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppRoster;
}

-(XMPPMessageArchiving *)xmppMessageArchiving{

    if (!_xmppMessageArchiving) {
        _xmppMessageArchiving = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:[XMPPMessageArchivingCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppMessageArchiving;
}

- (XMPPvCardTempModule *)xmppvCard
{
    if (_xmppvCard == nil) {
        _xmppvCard = [[XMPPvCardTempModule alloc] initWithvCardStorage:[XMPPvCardCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppvCard;
}

- (XMPPvCardAvatarModule *)xmppAvatar
{
    if (_xmppAvatar == nil) {
        _xmppAvatar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCard dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppAvatar;
}

- (XMPPIncomingFileTransfer *)xmppIncomingFile
{
    if (_xmppIncomingFile == nil) {
        _xmppIncomingFile = [[XMPPIncomingFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppIncomingFile;
}

- (XMPPOutgoingFileTransfer *)xmppOutgoingFile
{
    if (_xmppOutgoingFile == nil) {
        _xmppOutgoingFile = [[XMPPOutgoingFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppOutgoingFile;
}

- (NSMutableDictionary *)dict
{
    if (_dict == nil) {
        _dict = [NSMutableDictionary dictionary];
    }
    return _dict;
}


@end
