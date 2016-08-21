//
//  GroupchatViewController.m
//  EvenChat
//
//  Created by Even on 16/8/20.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "GroupchatViewController.h"
#import "EvenImageView.h"


@interface GroupchatViewController ()<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,XMPPOutgoingFileTransferDelegate>

@property (weak, nonatomic) IBOutlet UITableView *groupChatTableView;

// 查询结果控制器
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultController;

// 查询结果控制器
@property (nonatomic, strong) NSFetchedResultsController *realFetchedResultController;

@property (nonatomic, strong) NSArray *messages;

@property (nonatomic, strong) NSMutableDictionary *reals;

@end

@implementation GroupchatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[XMPPRoomManager shareInstance] joinRoomWithJID:self.groupChatJID andNickName:@"zhangsan"];
    
    // 自适应高度
    self.tableView.estimatedRowHeight = 200;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self realFreshData];
    [self refreshData];
}

- (void)refreshData
{
    // 查询
    [self.fetchedResultController performFetch:nil];
    
    self.messages = self.fetchedResultController.fetchedObjects;
    
    // 刷新到最底下
    if (self.messages.count > 0) {
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    // 刷新数据
    [self.tableView reloadData];
    
}

- (void)realFreshData
{
    // 查询
    [self.realFetchedResultController performFetch:nil];
    
    for (XMPPRoomOccupantCoreDataStorageObject *occupant in self.realFetchedResultController.fetchedObjects) {
        [self.reals setValue:occupant.realJID forKey:occupant.jidStr];
    }
    
    
}

// 邀请别人
- (IBAction)inviteSBBtnClicked:(id)sender {
    
    XMPPRoom *room = [XMPPRoomManager shareInstance].dict[self.groupChatJID.bare];
    
    [room inviteUser:[XMPPJID jidWithUser:@"imessage" domain:@"im.itcast.cn" resource:@"whitcast的iMac"] withMessage:@"来玩吧哥们~~~~"];
}

// 点击按钮,发送图片
- (IBAction)sendImageBtnClicked:(id)sender {
    // 访问相册
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    // 设置来源
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    // 设置代理
    picker.delegate = self;
    
    //    picker.allowsEditing = YES;
    // 展示
    [self presentViewController:picker animated:YES completion:nil];
    
}
/**
 *  点击相册中的资源后调用的方法
 *
 *  @param picker picker
 *  @param info   点击的相册或者视频的相关信息
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    //    // 发送文件
    //    NSError *error;
    //    [[CZXMPPManager shareInstance].xmppOutgoingFile sendData:UIImageJPEGRepresentation(image, 0.5) named:[[CZXMPPManager shareInstance].xmppStream generateUUID] toRecipient:[XMPPJID jidWithUser:self.contactJID.user domain:self.contactJID.domain resource:@"whitcast的iMac"] description:nil error:&error];
    //
    //    [[CZXMPPManager shareInstance].xmppOutgoingFile addDelegate:self delegateQueue:dispatch_get_main_queue()];
    //
    //    NSLog(@"%@",error);
    //
    // 发送一个离线消息的一种方式
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    
    NSString *imageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.groupChatJID.bareJID];
    
    [message addBody:imageStr];
    
    [[XMPPManager shareManager].xmppStream sendElement:message];
    //
    // 另一种离线文件的发送方式
    // 找一个代理服务器,先把这个文件发送给代理服务器,让代理服务器保存,如果对方上线,在发送给对方.
    
    
    
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}
#pragma mark - XMPPOutgoingFileTransferDelegate
//发送失败
- (void)xmppOutgoingFileTransfer:(XMPPOutgoingFileTransfer *)sender
                didFailWithError:(NSError *)error;
{
    NSLog(@"发送失败%@",error);
}
// 发送成功
- (void)xmppOutgoingFileTransferDidSucceed:(XMPPOutgoingFileTransfer *)sender;
{
    NSLog(@"发送成功");
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // chat 在message里面是单人聊天的时候调用的, groupchat这个是群组聊天时调用的属性
    XMPPMessage *message = [XMPPMessage messageWithType:@"groupchat" to:self.groupChatJID];
    
    [message addBody:textField.text];
    
    [[XMPPManager shareManager].xmppStream sendElement:message];
    
    
    textField.text = @"";
    
    return YES;
}

/**
 *  数据库文件发生变化后调用这个方法
 *
 *  @param controller
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller;
{
    [self realFreshData];
    [self refreshData];
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPRoomMessageCoreDataStorageObject *msg = self.messages[indexPath.row];
    
    XMPPvCardTemp *myvCardTemp = [XMPPManager shareManager].xmppvCard.myvCardTemp;
    
    UITableViewCell *cell;
    switch ([msg.message.subject intValue]) {
        case XMPP_TRANSFER_IMG: {  // 展示图片
            if (!msg.isFromMe) {
                
                cell = [tableView dequeueReusableCellWithIdentifier:@"receiveImageCell" forIndexPath:indexPath];
                // 头像
                UIImageView *imageView = [cell viewWithTag:1001];
                NSData *data = [[XMPPManager shareManager].xmppAvatar photoDataForJID:msg.jid];
                imageView.image = [[UIImage alloc] initWithData:data];
                
                // 展示图片
                EvenImageView *imageView1 = [cell viewWithTag:1004];
                
                NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject,msg.message.body];
                imageView1.image = [UIImage imageWithContentsOfFile:filePath];
                
                
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"sendImageCell" forIndexPath:indexPath];
                // 头像
                UIImageView *imageView = [cell viewWithTag:1001];
                imageView.image = [[UIImage alloc] initWithData:myvCardTemp.photo];
            }
            
        }
            
            break;
            
            // 展示其他
        default: {
            
            if (!msg.isFromMe) {
                
                cell = [tableView dequeueReusableCellWithIdentifier:@"receiveCell" forIndexPath:indexPath];
                
                XMPPJID *realJID = self.reals[msg.jidStr];
                
                
                UIImageView *imageView = [cell viewWithTag:1001];
                NSData *data = [[XMPPManager shareManager].xmppAvatar photoDataForJID:realJID];
                imageView.image = [[UIImage alloc] initWithData:data];
                
                
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"sendCell" forIndexPath:indexPath];
                UIImageView *imageView = [cell viewWithTag:1001];
                imageView.image = [[UIImage alloc] initWithData:myvCardTemp.photo];
            }
            UILabel *label = [cell viewWithTag:1002];
            label.text = msg.body;
            
        }
            break;
    }
    
    return cell;
}




- (NSFetchedResultsController *)fetchedResultController
{
    if (_fetchedResultController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomMessageCoreDataStorageObject" inManagedObjectContext:[XMPPRoomCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        //
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"roomJIDStr = %@", self.groupChatJID.bare];
        [fetchRequest setPredicate:predicate];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[XMPPRoomCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        _fetchedResultController.delegate = self;
    }
    return _fetchedResultController;
}

- (NSFetchedResultsController *)realFetchedResultController
{
    if (_realFetchedResultController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomOccupantCoreDataStorageObject" inManagedObjectContext:[XMPPRoomCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];

        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"jidStr" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _realFetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[XMPPRoomCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        // 添加代理,监听变化
        _realFetchedResultController.delegate = self;
        
    }
    return _realFetchedResultController;
}

- (NSArray *)messages
{
    if (_messages == nil) {
        _messages = [NSArray array];
    }
    return _messages;
}

- (NSMutableDictionary *)reals{
    if (_reals == nil) {
        _reals = [NSMutableDictionary dictionary];
    }
    return _reals;
}


@end
