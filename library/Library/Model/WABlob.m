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
#import "WABlob.h"
#import "WABlobContainer.h"

NSString * const WABlobPropertyKeyBlobType = @"BlobType";
NSString * const WABlobPropertyKeyCacheControl = @"Cache-Control";
NSString * const WABlobPropertyKeyContentEncoding = @"Content-Encoding";
NSString * const WABlobPropertyKeyContentLanguage = @"Content-Language";
NSString * const WABlobPropertyKeyContentLength = @"Content-Length";
NSString * const WABlobPropertyKeyContentMD5 = @"Content-MD5";
NSString * const WABlobPropertyKeyContentType = @"Content-Type";
NSString * const WABlobPropertyKeyEtag = @"Etag";
NSString * const WABlobPropertyKeyLastModified = @"Last-Modified";
NSString * const WABlobPropertyKeyLeaseStatus = @"LeaseStatus";
NSString * const WABlobPropertyKeySequenceNumber = @"x-ms-blob-sequence-number";

@implementation WABlob

@synthesize name = _name;
@synthesize URL = _URL;
@synthesize container = _container;
@synthesize properties = _properties; 


- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL container:(WABlobContainer *)container properties:(NSDictionary *)properties
{
    if ((self = [super init])) {
        _name = [name copy];
        _URL = [[NSURL URLWithString:URL] retain];
        _container = [container retain];
        _properties = [properties retain];
    }    
    
    return self;
}

- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL container:(WABlobContainer*)container 
{	
     return [self initBlobWithName:name URL:URL container:container properties:nil];	
}

- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL 
{	
    return [self initBlobWithName:name URL:URL container:nil];	
}

- (void) dealloc 
{
    [_name release];
    [_URL release];
    [_container release];
    [_properties release];
    
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Blob { name = %@, url = %@, container = %@, properties = %@ }", _name, _URL, _container, _properties.description];
}

@end
