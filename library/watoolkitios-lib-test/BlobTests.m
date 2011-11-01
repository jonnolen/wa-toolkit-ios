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

#import "BlobTests.h"
#import "WAToolkit.h"

//#define TEST_BLOBS

@implementation BlobTests

#ifdef TEST_BLOBS
- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testShouldContainersWithContinuationUsingCompletionHandlerDirect
{
    [directClient fetchBlobContainersWithContinuation:nil maxResult:100 usingCompletionHandler:^(NSArray* containers, WAResultContinuation *resultContinuation, NSError* error) 
     {
         STAssertNil(error, @"Error returned by fetchBlobContainersSegmented: %@", [error localizedDescription]);
         STAssertNotNil(containers, @"fetchBlobContainersSegmented returned nil");
         STAssertEquals((NSUInteger)100, containers.count, @"fetchBlobContainersSegmented returned more than maxresults");
         STAssertNotNil(resultContinuation.nextMarker, @"fetchBlobContainersSegmented did not return a marker key.");         
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];	
}

- (void)testShouldFetchBlobContainersWithCompletionHandlerDirect
{   
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         [directDelegate markAsComplete];
     }];
    
    [directDelegate waitForResponse];
}

-(void)testShouldAddDeleteBlobContainerWithCompletionHandlerDirect
{    
    NSLog(@"Executing TEST_ADD_DELETE_BLOB_CONTAINER");
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         containerCount = [containers count];
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient addBlobContainerNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         STAssertTrue((containerCount + 1 == [containers count] ),@"A new container doesn't appear to be added.");
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteBlobContainerNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         STAssertTrue((containerCount == [containers count] ),@"Unit test container doesn't appear to be deleted.");
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

-(void)testShouldAddBlobWithCompletionHandlerDirect
{
    NSLog(@"Executing TEST_ADD_BLOB");
    
    [directClient addBlobContainerNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    NSLog(@"container added: %@", randomContainerNameString);
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"cloud" ofType:@"jpg"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    __block WABlobContainer *mycontainer;
    [directClient fetchBlobContainerNamed:randomContainerNameString WithCompletionHandler:^(WABlobContainer *container, NSError *error)
     {
         [directDelegate markAsComplete];
         [directClient addBlobToContainer:container blobName:@"cloud.jpg" contentData:data contentType:@"image/jpeg" withCompletionHandler:^(NSError *error)
          {
              mycontainer = container;
              STAssertNil(error, @"Error returned by addBlob: %@", [error localizedDescription]);
              [directDelegate markAsComplete];
          }];
         [directDelegate waitForResponse];
         
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchBlobs:mycontainer withCompletionHandler:^(NSArray *blobs, NSError *error)
     {
         STAssertNil(error, @"Error returned by getBlobs: %@", [error localizedDescription]);
         STAssertTrue([blobs count] == 1, @"%i blobs were returned instead of 1",[blobs count]);         
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteBlobContainer:mycontainer withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
}

-(void)testShouldFetchBlobContainerBlobsWithCompletionHandlerProxy
{
    
    NSLog(@"Executing TEST_FETCH_BLOBCONTAINERS_PROXY");
    __block WABlobContainer *mycontainer;
    [proxyClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         mycontainer = [containers objectAtIndex:0];
         [proxyDelegate markAsComplete];
         
         NSLog(@"Executing TEST_FETCH_BLOBS_THROUGH_PROXY");
         [proxyClient fetchBlobs:mycontainer withCompletionHandler:^(NSArray *blobs, NSError *error)
          {
              STAssertNil(error, @"Error returned by getBlobs: %@", [error localizedDescription]);
              STAssertTrue([blobs count] > 0, @"%i blobs were returned instead of 1",[blobs count]);         
              [proxyDelegate markAsComplete];
          }];
         [proxyDelegate waitForResponse];
         
     }];    
    [proxyDelegate waitForResponse];
    
    NSLog(@"Executing TEST_ADD_BLOB_TO_CONTAINER_THROUGH_PROXY");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"cloud" ofType:@"jpg"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    [proxyClient addBlobToContainer:mycontainer blobName:@"cloud.jpg" contentData:data contentType:@"image/jpeg" withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by addBlob: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    NSLog(@"Dealy 5 seconds for adding blob data to be done in Azure Cloud!");
    NSDate *delay = [NSDate dateWithTimeIntervalSinceNow: 0.05 ];
    [NSThread sleepUntilDate:delay];
}
#endif

@end
