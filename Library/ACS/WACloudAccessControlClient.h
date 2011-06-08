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
#import <UIKit/UIKit.h>
#import "WACloudAccessToken.h"

extern NSString* CloudAccessTokenChanged;

@interface WACloudAccessControlClient : NSObject 
{
    NSURL* _serviceURL;
    NSString* _realm;
    NSString* _serviceNamespace;
}

@property (readonly) NSString* realm;
@property (readonly) NSString* serviceNamespace;

+ (WACloudAccessControlClient*)accessControlClientForNamespace:(NSString*)serviceNamespace realm:(NSString*)realm;

- (void)getIdentityProvidersWithBlock:(void (^)(NSArray*, NSError *))block;

- (void)requestAccessInNavigationController:(UINavigationController*)controller;

+ (WACloudAccessToken*)token;

@end
