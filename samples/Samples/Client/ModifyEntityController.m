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

#import "ModifyEntityController.h"
#import "Azure_Storage_ClientAppDelegate.h"
#import "UIViewController+ShowError.h"

@implementation ModifyEntityController

@synthesize entityTable;
@synthesize addUpdateButton;
@synthesize deleteButton;
@synthesize entity;
@synthesize queueMessage;
@synthesize queueName;
@synthesize messageString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	[entityTable release];
	[addUpdateButton release];
	[deleteButton release];
	[tableClient release];
	[entity release];
	[queueMessage release];
	[queueName release];
	[messageString release];
	[editFields release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	
	Azure_Storage_ClientAppDelegate		*appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    [super viewDidLoad];
	
	tableClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	tableClient.delegate = self;
		
	if ([self.navigationItem.title hasPrefix:@"Add"])
	{
		mode = MODE_ADD;
		//	[self.addUpdateButton setTitle:@"Add" forState:UIControlStateNormal];
		//	addUpdateButton.enabled = YES;
	}
	else if ([self.navigationItem.title hasPrefix:@"Edit"])
	{
		//	addUpdateButton.enabled = YES;
		mode = MODE_UPDATE;
	}
	else if ([self.navigationItem.title hasPrefix:@"Delete"])
	{
		mode = MODE_DELETE;
	}
	//	self.addUpdateButton.titleLabel.textAlignment = UITextAlignmentCenter;
	
	UIBarButtonItem* item;
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(addUpdate:)];
	self.navigationItem.rightBarButtonItem = item;
	[item release];
	
	editingRow = -1;
	[entityTable reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    tableClient.delegate = nil;
}

- (void)viewDidUnload
{
	entityTable = nil;
	addUpdateButton = nil;
	[self setDeleteButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)addUpdate:(id)sender
{
	if(editingRow >= 0)
	{
		UITextField* editField = [editFields objectAtIndex:editingRow];
		[editField resignFirstResponder];
	}
	
	UIActivityIndicatorView* activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:activity];
	self.navigationItem.rightBarButtonItem = item;
	[activity startAnimating];
	[activity release];
	[item release];
	
	if (mode == MODE_ADD)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			[tableClient insertEntity:entity];
		}
		else if ([self.navigationItem.title hasSuffix:@"Message"])
		{
			[tableClient addMessageToQueue:messageString queueName:queueName];
		}
	}
	else if (mode == MODE_UPDATE)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			[tableClient updateEntity:entity];
		}
	}
}

- (IBAction)delete:(id)sender
{
	
	if ([self.navigationItem.title hasSuffix:@"Entity"])
	{
		[tableClient deleteEntity:entity];
	}
	else if ([self.navigationItem.title hasSuffix:@"Message"])
	{
		[tableClient deleteQueueMessage:queueMessage queueName:queueName];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	if (mode == MODE_ADD)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			return ([[self.entity keys] count] + 2);
		}
		else if ([self.navigationItem.title hasSuffix:@"Message"])
		{
			return (1);
		}
	}
	else if (mode == MODE_UPDATE)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			return [[self.entity keys] count];
		}
	}
	else if (mode == MODE_DELETE)
	{
		if ([self.navigationItem.title hasSuffix:@"Message"])
		{
			return (QUEUE_MESSAGE_NUMBER_FIELDS);
		}
	}
	return (0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell2";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
	}
	
	if(!editFields)
	{
		NSInteger count = [self tableView:tableView numberOfRowsInSection:0];
		CGRect rc = CGRectMake(0, 0, 200, 30);
		editFields = [[NSMutableArray alloc] initWithCapacity:count];
		for(NSInteger n = 0; n < count; n++)
		{
			UITextField* textField = [[UITextField alloc] initWithFrame:rc];
			textField.delegate = self;
			textField.borderStyle = UITextBorderStyleRoundedRect;
			textField.tag = n;
			[editFields addObject:textField];
			[textField release];
			
			if(!n && mode == MODE_ADD)
			{
				[textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0];
			}
		}
	}
	
	UITextField* textField = [editFields objectAtIndex:indexPath.row];
	cell.accessoryView = textField;
	cell.selectionStyle = UITableViewCellEditingStyleNone;
	cell.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
	
	if (mode == MODE_ADD)
	{
		cell.detailTextLabel.text = @" ";
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			if (indexPath.row == 0)
			{
				cell.textLabel.text = @"PartitionKey";
				if ([entity.partitionKey length] > 0 && [entity.partitionKey isEqualToString:@" "] == NO)
				{
					textField.text = entity.partitionKey;
				}
			}
			else if (indexPath.row == 1)
			{
				cell.textLabel.text = @"RowKey";
				if ([entity.rowKey length] > 0 && [entity.rowKey isEqualToString:@" "] == NO)
				{
					textField.text = entity.rowKey;
				}
			}
			else
			{
				cell.textLabel.text = [[self.entity keys] objectAtIndex:(indexPath.row - 2)];
				if ([[entity objectForKey:[[self.entity keys] objectAtIndex:(indexPath.row - 2)]] length] > 0 && [[entity objectForKey:[[self.entity keys] objectAtIndex:(indexPath.row - 2)]] isEqualToString:@" "] == NO)
				{
					textField.text = [entity objectForKey:[[self.entity keys] objectAtIndex:(indexPath.row - 2)]];
				}
			}
		}
		else if ([self.navigationItem.title hasSuffix:@"Message"])
		{
			cell.textLabel.text = @"Message:";
			if ([messageString length] > 0)
			{
				textField.text = messageString;
			}
		}
	}
	else if (mode == MODE_UPDATE)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			cell.textLabel.text = [[self.entity keys] objectAtIndex:indexPath.row];
			if ([[self.entity objectForKey:[[self.entity keys] objectAtIndex:indexPath.row]] length])
			{
				textField.text = [self.entity objectForKey:[[self.entity keys] objectAtIndex:indexPath.row]];
			}
		}
	}
	else if (mode == MODE_DELETE)
	{
		switch (indexPath.row)
		{
			case 0:
				cell.textLabel.text = @"Message ID";
				textField.text = [queueMessage messageId];
				break;
			case 1:
				cell.textLabel.text = @"Insertion Time";
				textField.text = [queueMessage insertionTime];
				break;
			case 2:
				cell.textLabel.text = @"Expiration Time";
				textField.text = [queueMessage expirationTime];
				break;
			case 3:
				cell.textLabel.text = @"Pop Receipt";
				textField.text = [queueMessage popReceipt];
				break;
			case 4:
				cell.textLabel.text = @"Time Next Visible";
				textField.text = [queueMessage timeNextVisible];
				break;
			case 5:
				cell.textLabel.text = @"Message Text";
				textField.text = [queueMessage messageText];
				break;
			default:
				break;
		}
	}
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITextField* field = [editFields objectAtIndex:indexPath.row];
	[field becomeFirstResponder];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	editingRow = textField.tag;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	NSInteger rowToEdit = textField.tag;
	
	editingRow = -1;
	
	if (mode == MODE_ADD)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			if (rowToEdit == 0)
			{
				self.entity.partitionKey = textField.text;
			}
			else if (rowToEdit == 1)
			{
				self.entity.rowKey = textField.text;
			}
			else
			{
				[self.entity setObject:textField.text forKey:[[entity keys] objectAtIndex:(rowToEdit - 2)]];
			}
			
			// Only enable the button if the two required fields are filled
			if ([self.entity.partitionKey length] > 0 && [self.entity.rowKey length] > 0)
			{
				addUpdateButton.enabled = YES;
			}
			else
			{
				addUpdateButton.enabled = YES;
			}
		}
		else if ([self.navigationItem.title hasSuffix:@"Message"])
		{
			self.messageString = textField.text;
			addUpdateButton.enabled = YES;
		}
	}
	else if (mode == MODE_UPDATE)
	{
		if ([self.navigationItem.title hasSuffix:@"Entity"])
		{
			[self.entity setObject:textField.text forKey:[[entity keys] objectAtIndex:rowToEdit]];
		}
	}
	[textField resignFirstResponder];
	
	// Gets reset to the default button title; need to fix it again
	if (mode == MODE_ADD)
	{
		self.addUpdateButton.titleLabel.text = @"Add";
	}
	else
	{
		self.addUpdateButton.titleLabel.text = @"Update";
	}
	
	//	editingData = FALSE;
	//	[entityTable reloadData];
}

#pragma mark - CloudStorageClientDelegate methods

- (void)storageClient:(WACloudStorageClient *)client didFailRequest:request withError:error
{
	UIBarButtonItem* item;
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(addUpdate:)];
	self.navigationItem.rightBarButtonItem = item;
	[item release];

	[self showError:error];
}

- (void)storageClient:(WACloudStorageClient *)client didInsertEntity:(WATableEntity *)entity
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didUpdateEntity:(WATableEntity *)entity
{	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteEntity:(WATableEntity *)entity
{	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didAddMessageToQueue:(NSString *)message queueName:(NSString *)queueName
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName
{
	[self.navigationController popViewControllerAnimated:YES];
}
@end
