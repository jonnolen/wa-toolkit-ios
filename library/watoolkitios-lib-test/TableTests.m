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

#import "TableTests.h"
#import "WAToolkit.h"

//#define TEST_TABLES

@implementation TableTests

#ifdef TEST_TABLES
- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testShouldFetchTablesWithContinuationUsingCompletionHandlerDirect
{
    [directClient fetchTablesWithContinuation:nil usingCompletionHandler:^(NSArray *tables, WAResultContinuation *resultContinuation, NSError *error) 
     {
         STAssertNil(error, @"Error returned by fetchTablesSegmented: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"fetchTablesSegmented returned nil");
         STAssertNotNil(resultContinuation.nextTableKey, @"fetchTablesSegmented did not return a next table key.");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];	
}

-(void)testShouldFetchTablesWithCompletionHandlerDirect
{   
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];	
}

-(void)testShouldAddAndDeleteTableWithCompletionHandlerDirect
{   
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         tableCount = [tables count];
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue((tableCount + 1) == [tables count],@"Table didn't appear to be added."); 
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue(tableCount == [tables count],@"Table didn't appear to be deleted."); 
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldFetchTableEntitiesWithCompletionHandlerDirect
{
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:@"Developers"];
    [directClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray *entities, NSError *error)
     {
         STAssertNil(error, @"Error returned by getEntities: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldFetchTableEntitiesUsingPredicateWithCompletionHandlerDirect
{   
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    // insert an entry
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"Steve" forKey:@"Name"];
    
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    NSError *error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"Name = 'Steve' || Name = 'Eric' || Name = 'Ling'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	STAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [directClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray * entities, NSError * error) {
        STAssertNil(error, @"Error returned by getEntitiesFromTable: %@", [error localizedDescription]);
        STAssertNotNil(entities, @"getEntitiesFromTable returned nil");
        STAssertTrue(entities.count == 1, @"getEntitiesFromTable returned incorrect number of entities");
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldInsertTableEntityWithCompletionHandlerDirect
{
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Clean up after ourselves
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldUpdateTableEntityWithCompletionHandlerDirect
{
    NSLog(@"Executing TEST_UPDATE_TABLE_ENTITY");
    
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"299" forKey:@"Price"];
    
	// Setup before we run the actual test
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"299" forKey:@"Price"];
    [directClient updateEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by updateEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Clean up after ourselves
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldMergeTableEntityWithCompletionHandlerDirect
{
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"399" forKey:@"Price"];
	
	// Setup before we run the actual test
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"399" forKey:@"Price"];
    [directClient mergeEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by mergeEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Clean up after ourselves
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldDeleteTableEntityWithCompletionHandlerDirect
{
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
	
	// Setup before we run the actual test
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Now run the test
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldFetchTablesWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_FETCH_TABLES_PROXY");
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [proxyDelegate markAsComplete];
     }];
	
	[proxyDelegate waitForResponse];	
}

-(void)testShouldAddDeleteTableWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_ADD_DELETE_TABLE_PROXY");
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         tableCount = [tables count];
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue((tableCount + 1) == [tables count],@"Table didn't appear to be added."); 
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue(tableCount == [tables count],@"Table didn't appear to be deleted."); 
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldFetchTableEntitiesWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES_PROXY");
    
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:@"Developers"];
    [proxyClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray *entities, NSError *error)
     {
         STAssertNil(error, @"Error returned by getEntities: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldFetchTableEntitiesWithPredicateUsingCompletionHandlerProxy
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    // insert an entry
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"Steve" forKey:@"Name"];
    
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    NSError *error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"Name = 'Steve' || Name = 'Eric' || Name = 'Ling'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	STAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [proxyClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray * entities, NSError * error) {
        STAssertNil(error, @"Error returned by getEntitiesFromTable: %@", [error localizedDescription]);
        STAssertNotNil(entities, @"getEntitiesFromTable returned nil");
        STAssertTrue(entities.count == 1, @"getEntitiesFromTable returned incorrect number of entities");
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldInsertTableEntityWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_INSERT_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Clean up after ourselves
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldUpdateTableEntityWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_UPDATE_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"299" forKey:@"Price"];
    
	// Setup before we run the actual test
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"299" forKey:@"Price"];
    [proxyClient updateEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by updateEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Clean up after ourselves
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldMergeTableEntityWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_MERGE_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"399" forKey:@"Price"];
	
	// Setup before we run the actual test
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"399" forKey:@"Price"];
    [proxyClient mergeEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by mergeEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Clean up after ourselves
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldDeleteTableEntityWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_DELETE_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
	
	// Setup before we run the actual test
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Now run the test
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif
@end
