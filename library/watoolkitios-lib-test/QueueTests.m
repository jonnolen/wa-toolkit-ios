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

#import "QueueTests.h"
#import "WAToolkit.h"

//#define TEST_QUEUES

@implementation QueueTests

#ifdef TEST_QUEUES
- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

-(void)testShouldFetchQueuesWithCompletionHandlerDirect
{
    [directClient fetchQueuesWithCompletionHandler:^(NSArray* queues, NSError* error)
     {
         STAssertNil(error, @"Error returned from fetchQueue: %@",[error localizedDescription]);
         STAssertTrue([queues count] > 0, @"No queues were found under this account");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];
}

-(void)testShouldAddDeleteQueueWithCompletionHandlerDirect
{
    NSLog(@"Executing TEST_ADD_DELETE_QUEUE");
    
    [directClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
        
    }];
    [directDelegate waitForResponse];
    
    [directClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldFetchQueueMessagesWithCompletionHandlerDirect
{
    NSLog(@"Executing TEST_FETCH_QUEUE_MESSAGES");
    
    [directClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
        
    }];
    [directDelegate waitForResponse];
    
    [directClient addMessageToQueue:@"My Message test" queueName:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from adding message to Queue: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
	[directDelegate waitForResponse];
    
    [directClient fetchQueueMessages:randomQueueNameString withCompletionHandler:^(NSArray* queueMessages, NSError* error)
     {
         STAssertNil(error, @"Error returned from getQueueMessages: %@",[error localizedDescription]);
         STAssertTrue([queueMessages count] > 0, @"No queueMessages were found under this account");
         [directDelegate markAsComplete];
     }];
	[directDelegate waitForResponse];
    
    [directClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldFetchQueuesWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_FETCH_QUEUES_PROXY");
    
    [proxyClient fetchQueuesWithCompletionHandler:^(NSArray* queues, NSError* error)
     {
         STAssertNil(error, @"Error returned from fetchQueue: %@",[error localizedDescription]);
         STAssertTrue([queues count] > 0, @"No queues were found under this account");
         [proxyDelegate markAsComplete];
     }];
	
	[proxyDelegate waitForResponse];
}

-(void)testShouldAddDeleteQueueWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_ADD_DELETE_QUEUE_PPOXY");
    NSLog(@"Adding Queue Named: %@", randomQueueNameString);
    [proxyClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
        
    }];
    [proxyDelegate waitForResponse];
    
    NSLog(@"Deleting Queue Named: %@", randomQueueNameString);
    [proxyClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldFetchQueueMessagesWithCompletionHandlerProxy
{
    NSLog(@"Executing TEST_FETCH_QUEUE_MESSAGES_PROXY");
    NSLog(@"Adding Queue Named: %@", randomQueueNameString);
    [proxyClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
        
    }];
    [proxyDelegate waitForResponse];
    
    [proxyClient addMessageToQueue:@"My Message test" queueName:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from adding message to Queue: %@",[error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
	[proxyDelegate waitForResponse];
    
    [proxyClient fetchQueueMessages:randomQueueNameString withCompletionHandler:^(NSArray* queueMessages, NSError* error)
     {
         STAssertNil(error, @"Error returned from getQueueMessages: %@",[error localizedDescription]);
         STAssertTrue([queueMessages count] > 0, @"No queueMessages were found under this account");
         [proxyDelegate markAsComplete];
     }];
	[proxyDelegate waitForResponse];
    
    NSLog(@"Deleting Queue Named: %@", randomQueueNameString);
    [proxyClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

@end
