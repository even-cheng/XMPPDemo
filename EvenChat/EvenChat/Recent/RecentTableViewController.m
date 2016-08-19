//
//  RecentTableViewController.m
//  EvenChat
//
//  Created by Even on 16/8/19.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "RecentTableViewController.h"
#import "ChatViewController.h"

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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ChatViewController *chatVC = segue.destinationViewController;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    chatVC.contactJID = [self.recentPeople[indexPath.row] bareJid];
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


- (NSFetchedResultsController *)fetchResultController
{
    if (_fetchResultController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Contact_CoreDataObject" inManagedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        //        // 谓词
        //        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"<#format string#>", <#arguments#>];
        //        [fetchRequest setPredicate:predicate];
        // paixu
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
