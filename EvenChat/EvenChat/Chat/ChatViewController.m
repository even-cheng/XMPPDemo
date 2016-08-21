//
//  ChatViewController.m
//  EvenChat
//
//  Created by Even on 16/8/17.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "ChatViewController.h"
#import "EvenImageView.h"

@interface ChatViewController ()<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,XMPPOutgoingFileTransferDelegate>

//显示对话的tableView
@property (weak, nonatomic) IBOutlet UITableView *MessageTableView;

//查询结果控制器
@property (nonatomic, strong) NSFetchedResultsController *fetchResultController;

//对话信息
@property (strong,nonatomic) NSArray* messages;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    //自动行高
    self.MessageTableView.estimatedRowHeight = 150;
    
    //  设置让tableView根据autolayout自动计算行高
    self.MessageTableView.rowHeight = UITableViewAutomaticDimension;
    
    
    //查询刷新数据
    [self refreshData];

}

-(void)refreshData
{
    //查询
    [self.fetchResultController performFetch:nil];
    self.messages = self.fetchResultController.fetchedObjects;
    
    //刷新
    [self.MessageTableView reloadData];
    
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
    
    
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.contactJID.bareJID];
    
    [message addBody:imageStr];
    
    [[XMPPManager shareManager].xmppStream sendElement:message];
    //
    // 另一种离线文件的发送方式
    // 找一个代理服务器,先把这个文件发送给代理服务器,让代理服务器保存,如果对方上线,在发送给对方.
    
    
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark- UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{

    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.contactJID];
    
    //发送信息
    [message addBody:textField.text];
    
    [[XMPPManager shareManager].xmppStream sendElement:message];
    
    //清空输入框
    textField.text = @"";
    
    return YES;
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


#pragma mark - UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return self.messages.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    XMPPMessageArchiving_Message_CoreDataObject *msg = self.messages[indexPath.row];
    
    XMPPvCardTemp *vCardTemp = [XMPPManager shareManager].xmppvCard.myvCardTemp;
    
    UITableViewCell *cell;
    switch ([msg.message.subject intValue]) {
        case XMPP_TRANSFER_IMG: {  // 展示图片
            if (!msg.isOutgoing) {
                
                cell = [tableView dequeueReusableCellWithIdentifier:@"receiveImageCell" forIndexPath:indexPath];
                // 头像
                UIImageView *imageView = [cell viewWithTag:1001];
                NSData *data = [[XMPPManager shareManager].xmppAvatar photoDataForJID:msg.bareJid];
                imageView.image = [[UIImage alloc] initWithData:data];
                
                // 展示图片
                EvenImageView *imageView1 = [cell viewWithTag:1004];
                
                NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject,msg.message.body];
                imageView1.image = [UIImage imageWithContentsOfFile:filePath];
                
                
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"sendImageCell" forIndexPath:indexPath];
                // 头像
                UIImageView *imageView = [cell viewWithTag:1001];
                imageView.image = [[UIImage alloc] initWithData: vCardTemp.photo];
            }
            
        }
            
            break;
            
            // 展示其他
        default: {
            
            if (!msg.isOutgoing) {
                
                cell = [tableView dequeueReusableCellWithIdentifier:@"receiveCell" forIndexPath:indexPath];
                
                UIImageView *imageView = [cell viewWithTag:1001];
                NSData *data = [[XMPPManager shareManager].xmppAvatar photoDataForJID:msg.bareJid];
                imageView.image = [[UIImage alloc] initWithData:data];
                
                
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"sendCell" forIndexPath:indexPath];
                UIImageView *imageView = [cell viewWithTag:1001];
                imageView.image = [[UIImage alloc] initWithData:vCardTemp.photo];
            }
            UILabel *label = [cell viewWithTag:1002];
            label.text = msg.body;
            
        }
            break;
    }
    
    return cell;

}

#pragma mark - NSFetchedResultsControllerDelegate
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller{

    [self refreshData];
}



#pragma mark - 懒加载
-(NSArray *)messages{

    if (!_messages) {
        _messages = [NSArray array];
    }
    return _messages;
}

-(NSFetchedResultsController *)fetchResultController{

    if (!_fetchResultController) {

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", self.contactJID.bare];
        [fetchRequest setPredicate:predicate];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _fetchResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        _fetchResultController.delegate = self;
    }
    return _fetchResultController;
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
