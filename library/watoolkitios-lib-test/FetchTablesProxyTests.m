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

#import "FetchTablesProxyTests.h"
#import "WAToolkit.h"

@implementation FetchTablesProxyTests

#ifdef INTEGRATION_PROXY

- (void)setUp
{
    [super setUp];
    
    [proxyClient createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testShouldFetchTablesWithContinuationUsingCompletionHandlerDirect
{
    [proxyClient fetchTablesWithContinuation:nil usingCompletionHandler:^(NSArray *tables, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned by fetchTablesWithContinuation: %@", [error localizedDescription]);
        STAssertNotNil(tables, @"fetchTablesWithContinuation: returned nil");
        STAssertTrue(tables.count > 0, @"fetchTablesWithContinuation: returned no tables");
        [proxyDelegate markAsComplete];
    }];
	
	[proxyDelegate waitForResponse];	
}

-(void)testShouldFetchTablesWithCompletionHandlerDirect
{   
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) {
        STAssertNil(error, @"Error returned by fetchTablesWithCompletionHandler: %@", [error localizedDescription]);
        STAssertNotNil(tables, @"fetchTablesWithCompletionHandler: returned nil");
        STAssertTrue(tables.count > 0, @"fetchTablesWithCompletionHandler: returned no tables");
        [proxyDelegate markAsComplete];
    }];
	
	[proxyDelegate waitForResponse];	
}

#endif

@end
