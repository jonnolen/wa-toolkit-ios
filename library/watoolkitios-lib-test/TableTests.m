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
#import "WACloudStorageClient.h"
#import "WAAuthenticationCredential.h"
#import "WACloudStorageClientDelegate.h"
#import "WATableFetchRequest.h"
#import "WATableEntity.h"
#import "WAResultContinuation.h"

//#define TEST_TABLES

@implementation TableTests

#ifdef TEST_TABLES
- (void)setUp
{
    [super setUp];
    account = [NSString stringWithString:@"<your account>"];
    accessKey = [NSString stringWithString:@"<your account access key>"];
    
    directCredential = [WAAuthenticationCredential credentialWithAzureServiceAccount:account accessKey:accessKey];
    directClient = [WACloudStorageClient storageClientWithCredential:directCredential];
    directDelegate = [WACloudStorageClientDelegate createDelegateForClient:directClient];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testShouldBeAbleToFilterAndRetrieveTables
{
    //WAResultContinuation *resultContinuation = [[[WAResultContinuation alloc] initWithNextTableKey:nil] autorelease];
    [directClient fetchTablesSegmented:nil withCompletionHandler:^(NSArray* tables, WAResultContinuation *resultContinuation, NSError* error) 
     {
         STAssertNil(error, @"Error returned by fetchTablesSegmented: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"fetchTablesSegmented returned nil");
         STAssertNotNil(resultContinuation.nextTableKey, @"fetchTablesSegmented did not return a next table key.");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];	
}
#endif
@end
