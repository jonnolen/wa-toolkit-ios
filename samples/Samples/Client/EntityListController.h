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

#import <UIKit/UIKit.h>
#import "WACloudStorageClient.h"

#define ENTITY_TYPE_TABLE				1
#define ENTITY_TYPE_QUEUE				2
#define QUEUE_MESSAGE_NUMBER_FIELDS		6

@interface EntityListController : UITableViewController <WACloudStorageClientDelegate>
{
	
	WACloudStorageClient*	tableClient;
	NSMutableArray*			entityList;
	int						entityType;
}

@property (nonatomic, retain) NSArray *entityList;
@property (nonatomic, assign) int entityType;

- (IBAction)addEntity:(id)sender;

@end
