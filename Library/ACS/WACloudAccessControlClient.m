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

#import "WACloudAccessControlClient.h"
#import "WACloudURLRequest.h"
#import "WACloudAccessControlHomeRealm.h"
#import "WALoginProgressViewController.h"
#import "NSString+URLEncode.h"

static WACloudAccessToken* _token;

NSString* CloudAccessTokenChanged = @"CloudAccessTokenChanged";

@interface WACloudAccessControlHomeRealm (Private)

- (id)initWithPairs:(NSDictionary*)pairs emailSuffixes:(NSArray*)emailSuffixes;

@end

@implementation WACloudAccessControlClient

@synthesize realm = _realm;
@synthesize serviceNamespace = _serviceNamespace;

- (id)initForNamespace:(NSString*)serviceNamespace realm:(NSString*)realm
{
    if((self = [super init]))
    {
        _serviceNamespace = [serviceNamespace copy];
        _realm = [realm copy];
        
        NSString* url = [NSString stringWithFormat:@"https://%@.accesscontrol.windows.net/v2/metadata/IdentityProviders.js?protocol=javascriptnotify&realm=%@&version=1.0",
                         _serviceNamespace,
                         [_realm URLEncode]];
        _serviceURL = [[NSURL URLWithString:url] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_serviceNamespace release];
    [_realm release];
    [_serviceURL release];
    
    [super dealloc];
}

+ (WACloudAccessControlClient*)accessControlClientForNamespace:(NSString*)serviceNamespace realm:(NSString*)realm
{
    return [[[WACloudAccessControlClient alloc] initForNamespace:serviceNamespace realm:realm] autorelease];
}

- (void)getIdentityProvidersWithBlock:(void (^)(NSArray*, NSError *))block
{
    WACloudURLRequest* request = [WACloudURLRequest requestWithURL:_serviceURL];
    
    [request fetchDataWithCompletionHandler:^(NSData *data, NSError *error) 
    {
        if(error)
        {
            block(nil, error);
            return;
        }
        
        NSMutableArray* results = [NSMutableArray arrayWithCapacity:10];
        
        NSString* json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        json = [json stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
        
        NSArray* providers = [json componentsSeparatedByString:@"},{"];
        NSCharacterSet* objectMarkers = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
        NSTextCheckingResult* result;
        NSError* regexError = nil;
        NSRegularExpression* nameValuePair = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"]*)\":\"([^\"]*)\""  // @"\"Name\":\"([^\"]*)\",\"LoginUrl\":\"([^\"]*)\",\"LogoutUrl\":\"([^\"]*)\",\"ImageUrl\":\"([^\"]*)\",\"EmailAddressSuffixes\":\\[(.*)\\]" 
                                                                                       options:0 
                                                                                         error:&regexError];
        NSRegularExpression* emailSuffixes = [NSRegularExpression regularExpressionWithPattern:@"\"EmailAddressSuffixes\":\\[(\"([^\"]*)\",?)*\\]"  // @"\"Name\":\"([^\"]*)\",\"LoginUrl\":\"([^\"]*)\",\"LogoutUrl\":\"([^\"]*)\",\"ImageUrl\":\"([^\"]*)\",\"EmailAddressSuffixes\":\\[(.*)\\]" 
                                                                               options:0 
                                                                                 error:&regexError];
        for(NSString* provider in providers)
        {
            provider = [provider stringByTrimmingCharactersInSet:objectMarkers];
            
            NSArray* matches = [nameValuePair matchesInString:provider options:0 range:NSMakeRange(0, provider.length)];
            NSMutableDictionary* pairs = [NSMutableDictionary dictionaryWithCapacity:10];

            for(result in matches)
            {
                for(int n = 1; n < [result numberOfRanges]; n += 2)
                {
                    NSRange r = [result rangeAtIndex:n];
                    if(r.length > 0)
                    {
                        NSString* name = [provider substringWithRange:r];
                        
                        r = [result rangeAtIndex:n + 1];
                        if(r.length > 0)
                        {
                            NSString* value = [provider substringWithRange:r];
                            
                            [pairs setObject:value forKey:name];
                        }
                    }
                }
            }
            
            result = [emailSuffixes firstMatchInString:provider options:0 range:NSMakeRange(0, provider.length)];
            
            NSMutableArray* emailAddressSuffixes = [NSMutableArray arrayWithCapacity:10];
            for(int n = 1; n < [result numberOfRanges]; n++)
            {
                NSRange r = [result rangeAtIndex:n];
                if(r.length > 0)
                {
                    [emailAddressSuffixes addObject:[provider substringWithRange:r]];
                }
            }

			// mobile URL fixup
			NSString* name = [pairs objectForKey:@"Name"];
			if([name isEqualToString:@"Windows Live™ ID"])
			{
				NSString* loginURL = [pairs objectForKey:@"LoginUrl"];
				BOOL hasQuery = [loginURL rangeOfString:@"?"].length > 0;
				
				loginURL = [NSString stringWithFormat:hasQuery ? @"%@&pcexp=false" : @"%@?pcexp=false",
							loginURL];
				[pairs setObject:loginURL forKey:@"LoginUrl"];
			}
		
            WACloudAccessControlHomeRealm* homeRealm = [[WACloudAccessControlHomeRealm alloc] initWithPairs:pairs emailSuffixes:emailAddressSuffixes];
            [results addObject:homeRealm];
            [homeRealm release];
        }
        
        block([[results copy] autorelease], nil);
    }];
}

- (void)requestAccessInNavigationController:(UINavigationController*)controller
{
    UIViewController* progressController;
    
    progressController = [[WALoginProgressViewController alloc] initWithClient:self];
    
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:progressController];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    [controller presentModalViewController:navController animated:YES];
    
    [navController release];
    [progressController release];
}

+ (WACloudAccessToken*)token
{
    return _token;
}

+ (void)setToken:(WACloudAccessToken*)token
{
    if(token != _token)
    {
        [_token release];
        _token = [token retain];
        
        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:CloudAccessTokenChanged object:nil];
    }
}

@end
