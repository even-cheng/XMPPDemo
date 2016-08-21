//
//  RecentTableViewController.m
//  EvenChat
//
//  Created by Even on 16/8/19.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "RecentTableViewController.h"
#import "ChatViewController.h"
#import "GroupchatViewController.h"

@interface RecentTableViewController ()<NSFetchedResultsControllerDelegate>


@property (nonatomic, strong) NSFetchedResultsController *fetchResultController;

@property (nonatomic, strong) NSArray *recentPeople;

@end

@implementation RecentTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self refreshData];
}

// 查询操作
- (void)refreshData
{
    // 查询操作
    [self.fetchResultController performFetch:nil];
    
    self.recentPeople = self.fetchResultController.fetchedObjects;
    
    // 刷新
    [self.tableView reloadData];
}

// 点击后加入聊天群
- (IBAction)addRoomBtnClicked:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"聊天室" message:@"添加聊天室" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField *textField = alertController.textFields.lastObject;
        
        [[XMPPRoomManager shareInstance] joinRoomWithJID:[XMPPJID jidWithUser:textField.text domain:@"conference.even.chat" resource:nil] andNickName:@"zhangsan"];
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

    if ([segue.identifier isEqualToString:@"groupchat"]) {
        // 群聊
        GroupchatViewController *groupChatVC = segue.destinationViewController;
        groupChatVC.groupChatJID = [self.recentPeople[indexPath.row] bareJid];
        
        
    } else {
        // 单聊
        ChatViewController *chatVC = segue.destinationViewController;
        
        chatVC.contactJID = [self.recentPeople[indexPath.row] bareJid];
    }
}

/**
 *  数据库更新时调用的
 *
 *  @param controller
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller;
{
    [self refreshData];
}



#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.recentPeople.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recentCell" forIndexPath:indexPath];
    
    XMPPMessageArchiving_Contact_CoreDataObject *recent = self.recentPeople[indexPath.row];
    
    
    UILabel *nameLabel = [cell viewWithTag:1002];
    nameLabel.text = recent.bareJidStr;
    
    UILabel *messageLabel = [cell viewWithTag:1003];
    messageLabel.text = recent.mostRecentMessageBody;
    
    UIImageView *imageView = [cell viewWithTag:1001];
    NSData *data = [[XMPPManager shareManager].xmppAvatar photoDataForJID:recent.bareJid];
    imageView.image = [[UIImage alloc] initWithData:data];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *domin = [self.recentPeople[indexPath.row] bareJid].domain;
    
    if ([domin hasPrefix:@"even.chat"]) {
        // 单聊
        [self performSegueWithIdentifier:@"chat" sender:nil];
    } else {
        // 群聊
        [self performSegueWithIdentifier:@"groupchat" sender:nil];
        
    }
}


- (NSFetchedResultsController *)fetchResultController
{
    if (_fetchResultController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Contact_CoreDataObject" inManagedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];

        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"mostRecentMessageTimestamp" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        
        _fetchResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        _fetchResultController.delegate = self;
    }
    return _fetchResultController;
}

- (NSArray *)recentPeople
{
    if (_recentPeople == nil) {
        _recentPeople = [NSArray array];
    }
    return _recentPeople;
}






@end
