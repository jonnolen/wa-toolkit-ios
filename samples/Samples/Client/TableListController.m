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

#import "TableListController.h"
#import "Azure_Storage_ClientAppDelegate.h"
#import "CreateTableController.h"
#import "EntityListController.h"
#import "WAAuthenticationCredential.h"
#import "WABlobContainer.h"
#import "WABlob.h"
#import "BlobViewerController.h"
#import "WAQueue.h"
#import "WAConfiguration.h"
#import "UIViewController+ShowError.h"

typedef enum 
{
	TableStorage,
	QueueStorage,
	BlobStorage,
	BlobList
} StorageType;

@implementation TableListController

@synthesize storageList;
@synthesize selectedContainer;
@synthesize selectedQueue;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) 
	{
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	[storageClient release];
	[storageList release];
	[selectedContainer release];
	[selectedQueue release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (StorageType)storageType
{
	if ([self.navigationItem.title isEqualToString:@"Table Storage"])
	{
		return TableStorage;
	}
	else if ([self.navigationItem.title isEqualToString:@"Queue Storage"])
	{
		return QueueStorage;
	}
	else if ([self.navigationItem.title isEqualToString:@"Blob Storage"])
	{
		return BlobStorage;
	}
	else
	{
		return BlobList;
	}
}

- (BOOL)canModify
{
	WAConfiguration* config = [WAConfiguration sharedConfiguration];
	
	switch([self storageType])
	{
		case TableStorage:
		{
			return YES;
		}
			
		case QueueStorage:
		{
			return YES;
		}
			
		case BlobStorage:
		{
			return (config.connectionType == WAConnectDirect);
		}
			
		default:
		{
			return (self.selectedContainer != nil);
		}
	}
}

- (IBAction)modifyStorage:(id)sender
{
	CreateTableController *newController = [[CreateTableController alloc] initWithNibName:@"CreateTableController" bundle:nil];
	
	switch([self storageType])
	{
		case TableStorage:
		{
			newController.navigationItem.title = @"Create Table";
			break;
		}
			
		case QueueStorage:
		{
			newController.navigationItem.title = @"Create Queue";
			break;
		}
			
		case BlobStorage:
		{
			newController.navigationItem.title = @"Create Container";
			break;
		}
			
		default:
		{
			if (self.selectedContainer)
			{
				newController.navigationItem.title = @"Create Blob";
				newController.selectedContainer = self.selectedContainer;
			}
			else if (self.selectedQueue)
			{
				newController.navigationItem.title = @"Create Queue";
				newController.selectedQueue = self.selectedQueue;
			}
			break;
		}
	}
	
	[self.navigationController pushViewController:newController animated:YES];
	[newController release];

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{

    [super viewDidLoad];

	storageClient = nil;

	if([self canModify])
	{
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(modifyStorage:)] autorelease];
	}
}

- (void)viewDidUnload
{   
    [super viewDidUnload];
}

- (void)fetchData
{
	if ([self.navigationItem.title isEqualToString:@"Table Storage"])
	{
		[storageClient fetchTables];
	}
	else if ([self.navigationItem.title isEqualToString:@"Queue Storage"])
	{
		[storageClient fetchQueues];
	}
	else if ([self.navigationItem.title isEqualToString:@"Blob Storage"])
	{
		[storageClient fetchBlobContainers];
	}
	else
	{
		[storageClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
		 {
			 for (WABlobContainer *container in containers)
			 {
				 if ([container.name isEqualToString:self.navigationItem.title])
				 {
					 [storageClient fetchBlobs:container];
					 break;
				 }
			 }
		 }];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	
	Azure_Storage_ClientAppDelegate		*appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    [super viewWillAppear:animated];
	
	if(storageClient)
	{
		[storageClient release];
	}
	
	storageClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	storageClient.delegate = self;
	
	[self fetchData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    storageClient.delegate = nil;
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
    return [self.storageList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
	if ([self.navigationItem.title isEqualToString:@"Table Storage"])
	{
		cell.textLabel.text = [self.storageList objectAtIndex:indexPath.row];
	}
	else if ([self.navigationItem.title isEqualToString:@"Queue Storage"])
	{
		WAQueue *queue = [self.storageList objectAtIndex:indexPath.row];
		cell.textLabel.text = queue.queueName;
	}
	else if ([self.navigationItem.title isEqualToString:@"Blob Storage"])
	{
		WABlobContainer *container = [self.storageList objectAtIndex:indexPath.row];
		cell.textLabel.text = container.name;
	}
	else
	{
		WABlob *blob = [self.storageList objectAtIndex:indexPath.row];
		cell.textLabel.text = blob.name;
	}

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

	if ([self.navigationItem.title isEqualToString:@"Table Storage"])
	{
		EntityListController *newController = [[EntityListController alloc] initWithNibName:@"EntityListController" bundle:nil];
		
		newController.navigationItem.title = [self.storageList objectAtIndex:indexPath.row];
		newController.entityType = ENTITY_TYPE_TABLE;
		[self.navigationController pushViewController:newController animated:YES];
		[newController release];
	}
	else if ([self.navigationItem.title isEqualToString:@"Queue Storage"])
	{
		EntityListController *newController = [[EntityListController alloc] initWithNibName:@"EntityListController" bundle:nil];
		WAQueue *queue = [self.storageList objectAtIndex:indexPath.row];
		
		newController.navigationItem.title = queue.queueName;
		newController.entityType = ENTITY_TYPE_QUEUE;
		[self.navigationController pushViewController:newController animated:YES];
		[newController release];
	}
	else if ([self.navigationItem.title isEqualToString:@"Blob Storage"])
	{
		TableListController *newController = [[TableListController alloc] initWithNibName:@"TableListController" bundle:nil];
		
		newController.selectedContainer = [self.storageList objectAtIndex:indexPath.row];
		newController.navigationItem.title = newController.selectedContainer.name;
		[self.navigationController pushViewController:newController animated:YES];
		[newController release];
	}
	else
	{
		BlobViewerController *newController = [[BlobViewerController alloc] initWithNibName:@"BlobViewerController" bundle:nil];
		WABlob *blob = [self.storageList objectAtIndex:indexPath.row];
		
		newController.navigationItem.title = blob.name;
		newController.blob = blob;
		[self.navigationController pushViewController:newController animated:YES];
		[newController release];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self canModify];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	void(^block)(NSError*, NSString*) = ^(NSError* error, NSString* title)
	{
		self.tableView.allowsSelection = YES;
		self.navigationItem.backBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																								target:self 
																								action:@selector(modifyStorage:)] autorelease];
		
		if(error)
		{
			[self showError:error withTitle:title];
			return;
		}
		
		[storageList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
						 withRowAnimation:UITableViewScrollPositionBottom];
	};
	
	self.tableView.allowsSelection = NO;
	self.navigationItem.backBarButtonItem.enabled = NO;
	
	UIActivityIndicatorView* view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:view] autorelease];
	[view startAnimating];
	[view release];
	
	switch([self storageType])
	{
		case TableStorage:
		{
			[storageClient deleteTableNamed:[storageList objectAtIndex:indexPath.row] withCompletionHandler:^(NSError* error) 
			{
				block(error, @"Error Deleting Table");
			}];
			break;
		}
			
		case QueueStorage:
		{
			WAQueue *queue = [storageList objectAtIndex:indexPath.row];
			[storageClient deleteQueueNamed:queue.queueName withCompletionHandler:^(NSError* error) 
			{
				block(error, @"Error Deleting Queue");
			}];
			break;
		}
			
		case BlobStorage:
		{
			[storageClient deleteBlobContainer:[storageList objectAtIndex:indexPath.row] withCompletionHandler:^(NSError* error) 
			 {
				 block(error, @"Error Deleting Container");
			 }];
			break;
		}
			
		default:
		{
			[storageClient deleteBlob:[storageList objectAtIndex:indexPath.row] withCompletionHandler:^(NSError* error) 
			 {
				 block(error, @"Error Deleting Block");
			 }];
			break;
		}
	}
	
	// remove the item from your data
	//	[myItems removeObjectAtIndex:indexPath.row];
	
	// refresh the table view
	//[tableView reloadData];
}

#pragma mark - CloudStorageClientDelegate methods

- (void)storageClient:(WACloudStorageClient *)client didFailRequest:request withError:error
{
	[self showError:error];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchTables:(NSArray *)tables
{
	self.storageList = [[tables mutableCopy] autorelease];
	[self.tableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchBlobContainers:(NSArray *)containers
{
	self.storageList = [[containers mutableCopy] autorelease];
	[self.tableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchBlobs:(NSArray *)blobs inContainer:(WABlobContainer *)container
{
	self.storageList = [[blobs mutableCopy] autorelease];
	[self.tableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchQueues:(NSArray *)queues
{
	self.storageList = [[queues mutableCopy] autorelease];
	[self.tableView reloadData];
}

@end
