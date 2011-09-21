/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "EntityListController.h"
#import "Azure_Storage_ClientAppDelegate.h"
#import "ModifyEntityController.h"
#import "WAQueueMessage.h"
#import "EntityTableViewCell.h"
#import "UIViewController+ShowError.h"
#import "WAResultContinuation.h"

#define TOP_ROWS 20

@interface EntityListController()

- (void)fetchEntities;
- (void)editEntity:(NSUInteger)index;

@end

@implementation EntityListController

@synthesize entityList;
@synthesize entityType;
@synthesize resultContinuation=_resultContinuation;
@synthesize localEntityList = _localEntityList;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	[tableClient release];
	[entityList release];
    [_resultContinuation release];
    [_localEntityList release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma - Private methods

- (void)fetchEntities
{
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:self.navigationItem.title];
    fetchRequest.resultContinuation = self.resultContinuation;
    fetchRequest.topRows = TOP_ROWS;
    [tableClient fetchEntitiesSegmented:fetchRequest];
}

- (void)editEntity:(NSUInteger)index
{
    ModifyEntityController *newController = [[ModifyEntityController alloc] initWithNibName:@"ModifyEntityController" bundle:nil];
    newController.navigationItem.title = @"Edit Entity";
    newController.entity = [self.entityList objectAtIndex:index];
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
}

#pragma - Action methods

- (IBAction)addEntity:(id)sender
{
	
	ModifyEntityController	*newController = [[ModifyEntityController alloc] initWithNibName:@"ModifyEntityController" bundle:nil];
	
	if ([self.localEntityList count] > 0 || entityType == ENTITY_TYPE_QUEUE) {
		if (entityType == ENTITY_TYPE_TABLE) {
			newController.navigationItem.title = @"Add Entity";
			newController.entity = [WATableEntity createEntityForTable:self.navigationItem.title];
			for (NSString *key in [[self.entityList objectAtIndex:0] keys]) {
				[newController.entity setObject:@"" forKey:key];
			}
		} else if (entityType == ENTITY_TYPE_QUEUE) {
			newController.navigationItem.title = @"Add Queue Message";
			newController.queueName = self.navigationItem.title;
		}
		newController.addUpdateButton.titleLabel.text = @"Add";
		[self.navigationController pushViewController:newController animated:YES];
		newController.deleteButton.enabled = NO;
    }
    [newController release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	Azure_Storage_ClientAppDelegate *appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    [super viewDidLoad];
	
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																							target:self 
																							action:@selector(addEntity:)] autorelease];
	tableClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	tableClient.delegate = self;
    _localEntityList = [[NSMutableArray alloc] initWithCapacity:20];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	if (entityType == ENTITY_TYPE_TABLE) {
		[self fetchEntities];
	} else if (entityType == ENTITY_TYPE_QUEUE) {
		[tableClient peekQueueMessages:self.navigationItem.title fetchCount:1000];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    tableClient.delegate = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSUInteger count = self.entityList.count;
    NSUInteger localCount = self.localEntityList.count;
    
    if (count >= TOP_ROWS) {
        localCount += 1;
    }
    
    return localCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString* CellIdentifier = @"Cell2";
    
    EntityTableViewCell *cell = (EntityTableViewCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (indexPath.row != self.localEntityList.count) {
        if (cell == nil) {
            cell = [[[EntityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
	
        if (entityType == ENTITY_TYPE_TABLE) {
            WATableEntity *entity = [self.localEntityList objectAtIndex:indexPath.row];
            [cell setKeysAndObjects:@"PartitionKey", [entity partitionKey], @"RowKey", [entity rowKey], entity, nil];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        } else if (entityType == ENTITY_TYPE_QUEUE) {
            WAQueueMessage *queueMessage = [self.localEntityList objectAtIndex:indexPath.row];
            [cell setKeysAndObjects:queueMessage, nil];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
	
    if (self.entityList.count == TOP_ROWS) {
        if (indexPath.row == self.localEntityList.count) {
            UITableViewCell *loadMoreCell = [tableView dequeueReusableCellWithIdentifier:@"LoadMore"];
            if (loadMoreCell == nil) {
                loadMoreCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadMore"] autorelease];
            }
            
            UILabel *loadMore =[[UILabel alloc] initWithFrame:CGRectMake(0,0,362,40)];
            loadMore.textColor = [UIColor blackColor];
            loadMore.highlightedTextColor = [UIColor darkGrayColor];
            loadMore.backgroundColor = [UIColor clearColor];
            //loadMore.font = [UIFont fontWithName:@"Verdana" size:20];
            loadMore.textAlignment = UITextAlignmentCenter;
            loadMore.font = [UIFont boldSystemFontOfSize:20];
            loadMore.text = @"Show more results...";
            [loadMoreCell addSubview:loadMore];
            [loadMore release];
            return loadMoreCell;
        }
    }
    
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int count = 0;
	
    if (indexPath.row >= self.localEntityList.count) {
        return 40;  
    } else if (entityType == ENTITY_TYPE_TABLE) {
		WATableEntity *entity = [self.localEntityList objectAtIndex:indexPath.row];
		count = entity.keys.count + 2;
	} else if (entityType == ENTITY_TYPE_QUEUE) {
		count = 6;
	} else {
		return 44;
	}
	
	return 12 + count * 25;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (entityType == ENTITY_TYPE_TABLE) {
        if (self.entityList.count == TOP_ROWS && indexPath.row == self.localEntityList.count) {
            //if (indexPath.row == self.localEntityList.count) {
                [self fetchEntities];
                [entityList removeAllObjects];
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                                      withRowAnimation:UITableViewScrollPositionBottom];
            //} else {
            //    [self editEntity:indexPath.row];
            //}
        } else {
            [self editEntity:indexPath.row];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.entityList.count == TOP_ROWS && indexPath.row == self.localEntityList.count) {
        return NO;
    }
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	void(^block)(NSError*) = ^(NSError* error) 
	{
		if (error) {
			[self showError:error withTitle:@"Deleting Entry"];
			return;
		}
		
		[self.localEntityList removeObjectAtIndex:indexPath.row];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
							  withRowAnimation:UITableViewScrollPositionBottom];
		
		if (entityType == ENTITY_TYPE_TABLE && !entityList.count) {
			self.navigationItem.rightBarButtonItem = nil;
		}
	};	
	
	if (entityType == ENTITY_TYPE_TABLE) {
		WATableEntity *entity = [self.localEntityList objectAtIndex:indexPath.row];
		[tableClient deleteEntity:entity withCompletionHandler:block];
	} else if (entityType == ENTITY_TYPE_QUEUE) {
		WAQueueMessage *queueMessage = [self.localEntityList objectAtIndex:indexPath.row];
		
		[tableClient deleteQueueMessage:queueMessage 
							  queueName:self.navigationItem.title 
				  withCompletionHandler:block];
	}

}

#pragma mark - CloudStorageClientDelegate methods

- (void)storageClient:(WACloudStorageClient *)client didFailRequest:request withError:error
{
	[self showError:error];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchEntities:(NSArray *)entities fromTableNamed:(NSString *)tableName withResultContinuation:(WAResultContinuation *)resultContinuation
{
    self.entityList = [[entities mutableCopy] autorelease];
    self.resultContinuation = resultContinuation;
	if ([entities count] == 0) {
		self.navigationItem.rightBarButtonItem = nil;
	}
    [self.localEntityList addObjectsFromArray:self.entityList];    
	[self.tableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didPeekQueueMessages:(NSArray *)queueMessages
{
	self.entityList = [[queueMessages mutableCopy] autorelease];
    [self.localEntityList addObjectsFromArray:self.entityList];
	[self.tableView reloadData];
}

@end
