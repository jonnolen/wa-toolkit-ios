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

#import <Foundation/Foundation.h>

/*! WAContinuationType represents the type of continuation in a WAResultContinuation.*/
typedef enum WAContinuationType {
    WAContinuationNone = 0,
    WAContinuationBlob = 1,
    WAContinuationQueue = 2,
    WAContinuationContainer = 3,
    WAContinuationTable = 4,
    WAContinuationEntity = 5
} WAContinuationType;

/*! WAResultContinuation is a class used to represent continuation tokens used with paging Windows Azure data.*/
@interface WAResultContinuation : NSObject {
@private
    NSString *_nextParitionKey;
    NSString *_nextRowKey;
    NSString *_nextTableKey;
    NSString *_nextMarker;
    enum WAContinuationType _continuationType;
}

/*! The next partition key in a continuation. */
@property (nonatomic, readonly) NSString *nextPartitionKey;
/*! The next row key in a continuation. */
@property (nonatomic, readonly) NSString *nextRowKey;
/*! The next table key in a continuation. */
@property (nonatomic, readonly) NSString *nextTableKey;
/*! The next marker key in a continuation. */
@property (nonatomic, readonly) NSString *nextMarker;
/*! The continuation type. */
@property (nonatomic, readonly) WAContinuationType continuationType;
/*! Determines if there is a continuation. */
@property (nonatomic, readonly) BOOL hasContinuation;

/*! Intialize a new continuation with the next partition and row key. */
- (id)initWithNextParitionKey:(NSString*)nextParitionKey nextRowKey:(NSString*)nextRowKey;

/*! Intialize a new continuation with the next table key. */
- (id)initWithNextTableKey:(NSString*)nextTableKey;

/*! Intialize a new continuation with the container marker. */
- (id)initWithContainerMarker:(NSString*)marker;

@end
