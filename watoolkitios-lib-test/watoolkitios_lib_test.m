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

#import "watoolkitios_lib_test.h"
#import "WACloudStorageClient.h"
#import "WAAuthenticationCredential.h"
#import "WACloudStorageClientDelegate.h"
#import "WATableFetchRequest.h"
#import "WATableEntity.h"
#import "WAQueue.h"
#import "WAQueueMessage.h"

// Tests for blob related functions
#define TEST_FETCH_BLOB_CONTAINERS
#define TEST_ADD_DELETE_BLOB_CONTAINER
#define TEST_ADD_BLOB

// Tests for table related functions
#define TEST_FETCH_TABLES
#define TEST_ADD_DELETE_TABLE
#define TEST_FETCH_TABLE_ENTITIES
#define TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE
#define TEST_INSERT_TABLE_ENTITY
#define TEST_UPDATE_TABLE_ENTITY
#define TEST_MERGE_TABLE_ENTITY
#define TEST_DELETE_TABLE_ENTITY

// Tests for queue related functions
#define TEST_FETCH_QUEUES
#define TEST_ADD_DELETE_QUEUE
#define TEST_FETCH_QUEUE_MESSAGES

// Account details for testing
NSString *account = @"iostest";
NSString *accessKey = @"/9seXadQ9HwOpXUO1jKxFN8qVwluGWrRkDQS+wZrghS9a1wPNh1ysHBvj0q0zL34E/qcWkmygEBqNFSz6Yk2eA==";

// Use for test setup
WAAuthenticationCredential *credential;
WACloudStorageClient *client;
WACloudStorageClientDelegate *delegate;

// Used for container and table cleanup
NSString *unitTestContainerName = @"unitestcontainer";
NSString *unitTestQueueName = @"unittestqueue";
NSString *unitTestTableName = @"unittesttable";
NSString *randomContainerNameString;
NSString *randomQueueNameString;
NSString *randomTableNameString;
int containerCount = 0;
int tableCount = 0;

@implementation watoolkitios_lib_test

- (void)setUp
{
    credential = [WAAuthenticationCredential credentialWithAzureServiceAccount:account accessKey:accessKey];
    client = [WACloudStorageClient storageClientWithCredential:credential];
    delegate = [WACloudStorageClientDelegate createDelegateForClient:client];
    
    randomTableNameString = [NSString stringWithFormat:@"%@%d",unitTestTableName,arc4random() % 1000];
    randomContainerNameString = [NSString stringWithFormat:@"%@%d",unitTestContainerName,arc4random() % 1000];
    randomQueueNameString = [NSString stringWithFormat:@"%@%d",unitTestQueueName,arc4random() % 1000];
    
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}


#ifdef TEST_FETCH_BLOB_CONTAINERS
- (void)testFetchBlobContainers_WithCompletionHandler_ReturnsContainerList 
{    
    NSLog(@"Executing TEST_FETCH_BLOB_CONTAINERS");
    [client fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         [delegate markAsComplete];
     }];
    
    [delegate waitForResponse];
}
#endif

#ifdef TEST_ADD_DELETE_BLOB_CONTAINER
-(void)testAddDeleteBlobContainer_WithCompletionHandler_ContainerAddedAndDeleted
{    
    NSLog(@"Executing TEST_ADD_DELETE_BLOB_CONTAINER");
    [client fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         containerCount = [containers count];
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client addBlobContainer:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         STAssertTrue((containerCount + 1 == [containers count] ),@"A new container doesn't appear to be added.");
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    WABlobContainer *container = [[WABlobContainer alloc] initContainerWithName:randomContainerNameString URL:[NSString stringWithFormat:@"http://iostest.blob.core.windows.net/%@",randomContainerNameString] metadata:@" "];
    [client deleteBlobContainer:container withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         STAssertTrue((containerCount == [containers count] ),@"Unit test container doesn't appear to be deleted.");
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_ADD_BLOB
-(void)testAddBlob_WithCompletionHandler_BlobAdded
{
    NSLog(@"Executing TEST_ADD_BLOB");
    
    [client addBlobContainer:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"cloud" ofType:@"jpg"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    WABlobContainer *container = [[WABlobContainer alloc] initContainerWithName:randomContainerNameString URL:[NSString stringWithFormat:@"http://iostest.blob.core.windows.net/%@",randomContainerNameString] metadata:@" "];
    
    [client addBlobToContainer:container blobName:@"cloud.jpg" contentData:data contentType:@"image/jpeg" withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by addBlob: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client fetchBlobs:container withCompletionHandler:^(NSArray *blobs, NSError *error)
     {
         STAssertNil(error, @"Error returned by getBlobs: %@", [error localizedDescription]);
         STAssertTrue([blobs count] == 1, @"%i blobs were returned instead of 1",[blobs count]);         
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client deleteBlobContainer:container withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
         [delegate markAsComplete];
     }];
     [delegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLES
-(void)testFetchTables_WithCompletionHandler_ReturnsTableList
{
    NSLog(@"Executing TEST_FETCH_TABLES");
    
    [client fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [delegate markAsComplete];
     }];
	
	[delegate waitForResponse];	
}
#endif

#ifdef TEST_ADD_DELETE_TABLE
-(void)testAddDeleteTable_WithCompletionHandler_TableAddedAndDeleted
{
    NSLog(@"Executing TEST_ADD_DELETE_TABLE");
    
    [client fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         tableCount = [tables count];
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue((tableCount + 1) == [tables count],@"Table didn't appear to be added."); 
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client deleteTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue(tableCount == [tables count],@"Table didn't appear to be deleted."); 
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLE_ENTITIES
-(void)testFetchTableEntities_WithCompletionHandler_ReturnsTableEntities
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES");
    
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:@"Developers"];
    [client fetchEntities:fetchRequest withCompletionHandler:^(NSArray *entities, NSError *error)
     {
         STAssertNil(error, @"Error returned by getEntities: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE
-(void)testFetchTableEntitiesWithPredicate_WithCompletionHandler_ReturnsFilteredTableEntities
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE");
    
    // first create a table to test against
    [client createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    // insert an entry
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"Steve" forKey:@"Name"];
    
    [client insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    NSError *error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"Name = 'Steve' || Name = 'Eric' || Name = 'Ling'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	STAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [client fetchEntities:fetchRequest withCompletionHandler:^(NSArray * entities, NSError * error) {
        STAssertNil(error, @"Error returned by getEntitiesFromTable: %@", [error localizedDescription]);
        STAssertNotNil(entities, @"getEntitiesFromTable returned nil");
        STAssertTrue(entities.count == 1, @"getEntitiesFromTable returned incorrect number of entities");
        [delegate markAsComplete];
    }];
    [delegate waitForResponse];
    
    [client deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_INSERT_TABLE_ENTITY
-(void)testInsertTableEntity_withCompletionHandler_InsertsEntityIntoTable
{
    NSLog(@"Executing TEST_INSERT_TABLE_ENTITY");
    
    // first create a table to test against
    [client createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    
    [client insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	// Clean up after ourselves
    [client deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_UPDATE_TABLE_ENTITY
-(void)testUpdateTableEntity_withCompletionHandler_UpdatesEntityInTable
{
    NSLog(@"Executing TEST_UPDATE_TABLE_ENTITY");

    // first create a table to test against
    [client createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"299" forKey:@"Price"];
    
	// Setup before we run the actual test
    [client insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"299" forKey:@"Price"];
    [client updateEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by updateEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	// Clean up after ourselves
    [client deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_MERGE_TABLE_ENTITY
-(void)testMergeTableEntity_WithCompletionHandler_MergesExistingTableEntity
{
    NSLog(@"Executing TEST_MERGE_TABLE_ENTITY");
    
    // first create a table to test against
    [client createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"399" forKey:@"Price"];
	
	// Setup before we run the actual test
    [client insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"399" forKey:@"Price"];
    [client mergeEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by mergeEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	// Clean up after ourselves
    [client deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_DELETE_TABLE_ENTITY
-(void)testDeleteTableEntity_WithCompletionHandler_TableEntityIsDeleted
{
    NSLog(@"Executing TEST_DELETE_TABLE_ENTITY");
    
    // first create a table to test against
    [client createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
	
	// Setup before we run the actual test
    [client insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
	// Now run the test
    [client deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [delegate markAsComplete];
     }];
    [delegate waitForResponse];
    
    [client deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_QUEUES
-(void)testFetchQueues_WithCompletionHandler_ReturnsListOfQueues 
{
    NSLog(@"Executing TEST_FETCH_QUEUES");
    
    [client fetchQueuesWithCompletionHandler:^(NSArray* queues, NSError* error)
     {
         STAssertNil(error, @"Error returned from fetchQueue: %@",[error localizedDescription]);
         STAssertTrue([queues count] > 0, @"No queues were found under this account");
         [delegate markAsComplete];
     }];
	
	[delegate waitForResponse];
}
#endif

#ifdef TEST_ADD_DELETE_QUEUE
-(void)testAddDeleteQueue_WithCompletionHandler_QueueAddedAndDeleted
{
    NSLog(@"Executing TEST_ADD_DELETE_QUEUE");
    
    [client addQueue:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
         [delegate markAsComplete];
        
    }];
    [delegate waitForResponse];
    
    [client deleteQueue:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_QUEUE_MESSAGES
-(void)testFetchQueueMessages_WithCompletionHandler_QueueMessageAddedAndReturned 
{
    NSLog(@"Executing TEST_FETCH_QUEUE_MESSAGES");
    
    [client addQueue:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [delegate markAsComplete];
        
    }];
    [delegate waitForResponse];
    
    [client addMessageToQueue:@"My Message test" queueName:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from adding message to Queue: %@",[error localizedDescription]);
        [delegate markAsComplete];
     }];
	[delegate waitForResponse];
    
    [client fetchQueueMessages:randomQueueNameString withCompletionHandler:^(NSArray* queueMessages, NSError* error)
     {
         STAssertNil(error, @"Error returned from getQueueMessages: %@",[error localizedDescription]);
         STAssertTrue([queueMessages count] > 0, @"No queueMessages were found under this account");
         [delegate markAsComplete];
     }];
	[delegate waitForResponse];
    
    [client deleteQueue:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [delegate markAsComplete];
     }];
    [delegate waitForResponse];
}

#endif


@end
