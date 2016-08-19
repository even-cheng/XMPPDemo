//
//  ContactTableViewController.m
//  EvenChat
//
//  Created by Even on 16/8/17.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "ContactTableViewController.h"
#import "ChatViewController.h"

@interface ContactTableViewController ()<NSFetchedResultsControllerDelegate>

//查询结果控制器
@property (nonatomic, strong) NSFetchedResultsController *fetchResultController;

//联系人数组
@property (nonatomic, strong) NSArray *contactsArr;


@end

@implementation ContactTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //查询
    [self refreshData];
}

//刷新
-(void)refreshData
{
    //进行查询
    [self.fetchResultController performFetch:nil];
    self.contactsArr = self.fetchResultController.fetchedObjects;
    
    //刷新数据
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    //获取目标控制器
    ChatViewController* chatVC = segue.destinationViewController;
    
    //获取对应的联系人数据
    NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
    
    //赋值
    chatVC.contactJID = [self.contactsArr[indexPath.row] jid];
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.contactsArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    
    UILabel *label = [cell viewWithTag:1002];
    label.text = [self.contactsArr[indexPath.row] jidStr];
    
    UIImageView *imageView = [cell viewWithTag:1001];
    NSData *data = [[XMPPManager shareManager].xmppAvatar photoDataForJID:[self.contactsArr[indexPath.row] jid]];
    imageView.image = [[UIImage alloc] initWithData:data];
    
    return cell;
}

//添加好友
- (IBAction)addContacts:(UIBarButtonItem *)sender {
    
    [[XMPPManager shareManager].xmppRoster addUser:[XMPPJID jidWithUser:@"zhangsan" domain:@"even.chat" resource:@"Even"] withNickname:@"张三"];
}

-(NSFetchedResultsController *)fetchResultController{

    if (!_fetchResultController) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        //排序
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"jidStr"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _fetchResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        //设置代理
        _fetchResultController.delegate = self;
    }
    return _fetchResultController;
}

-(NSArray *)contactsArr{

    if (!_contactsArr) {
        _contactsArr = [NSArray array];
    }
    return _contactsArr;
}



#pragma mark - NSFetchedResultsControllerDelegate
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller{

    //刷新数据
    [self refreshData];
}













@end
