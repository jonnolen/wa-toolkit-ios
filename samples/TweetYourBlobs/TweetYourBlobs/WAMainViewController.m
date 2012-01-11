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

#import "WAMainViewController.h"
#import "WAKeychainController.h"
#import "WABitlyHandler.h"
#import "WABlobTweet.h"
#import "WABitlyCredential.h"
#import "WALocationHandler.h"
#import "WALoginHandler.h"
#import "WABitlyResponse.h"
#import <Twitter/Twitter.h>

typedef enum {
    kTextFieldContainer = 0,
    kTextFieldBlob
} TextFieldTypes;

typedef enum {
    kTableCellContainer = 0,
    kTableCellMakePublic,
    kTableCellBlob,
    kTableCellIncludeLocation
} TableCellTypes;

typedef enum { 
    kButtonIndexDone = 1,
    kButtonIndexCancel
}
ButtonIndexTYpes;

@interface WAMainViewController()

- (void)retrieveBitlyInformation;
- (void)postToBlobStorage;
- (void)unlockView;
- (void)lockView;
- (void)displayAlert:(NSString *)message;
- (void)tweet;

@end

@implementation WAMainViewController

@synthesize containerNameTextField = _containerNameTextField;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _blobTweet = [[WABlobTweet alloc] init];
    _bitlyCredential = [[WABitlyCredential alloc] init];
    _locationHandler = [[WALocationHandler alloc] init];
    _locationHandler.delegate = self;
    [_locationHandler startUpdatingCurrentLocation];
    
    WALoginHandler *loginContoller = [[WALoginHandler alloc] initWithStoryBoard:self.storyboard navigationController:self.navigationController];
    [loginContoller login:^(WAAuthenticationCredential *authenticationCredential) {
        _authenticationCredential = authenticationCredential;
        [self.containerNameTextField becomeFirstResponder];
    }];
}

- (void)viewDidUnload
{
    _blobTweet = nil;
    _bitlyCredential = nil;
    _locationHandler.delegate = nil;
    _locationHandler = nil;
    
    [self setContainerNameTextField:nil];
    [super viewDidUnload];
}


#pragma mark - UITableViewDelegate methods
/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(10, 3, tableView.bounds.size.width - 10, 40)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    switch (section) {
        case 0:
            label.text = @"Container";
            break;
        case 1:
            label.text = @"Blob";
        default:
            break;
    }
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:18];
    label.frame = CGRectMake(13, 0,customView.bounds.size.width - 13, 40);
    [customView addSubview:label];
    return customView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 0) {
        return;
    }
    
    BOOL checked = NO;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        checked = YES;
    }
    
    switch (cell.tag) {
        case kTableCellMakePublic:
            _blobTweet.makeContainerPublic = checked;
            break;
            
        case kTableCellIncludeLocation:
            _blobTweet.includeLocationData = checked;
            break;
            
        default:
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo
{
    _blobTweet.image = selectedImage;
    self.navigationItem.leftBarButtonItem.enabled = [_blobTweet isValid];
    
    [self dismissModalViewControllerAnimated:YES];   
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.navigationItem.leftBarButtonItem.enabled = [_blobTweet isValid];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case kTextFieldContainer:
            _blobTweet.containerName = textField.text;
            break;
            
        case kTextFieldBlob:
            _blobTweet.blobName = textField.text;
            break;
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	
	NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
	/*
	if (!newStr.length) {
		createButton.enabled = NO;
        uploadDefaultImageButton.enabled = YES;
		return YES;
	}
	*/
	if ([newStr rangeOfString:@"^[A-Za-z][A-Za-z0-9\\-\\_]*" 
                      options:NSRegularExpressionSearch].length == newStr.length) {
		//createButton.enabled = YES;
        //uploadDefaultImageButton.enabled = YES;
		return YES;
	}
    
	return NO;
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    if (buttonIndex == kButtonIndexDone) {
        UITextField *nameField = [alertView textFieldAtIndex:0];
        UITextField *apiKeyField = [alertView textFieldAtIndex:1];
        [_bitlyCredential saveLogin:nameField.text apiKey:apiKeyField.text];
        
        [self postToBlobStorage];
    } 
}

#pragma mark - WABitlyControllerDelegate methods

- (void)requestSucceeded:(WABitlyHandler *)request forLongURL:(NSURL *)longURL withShortURLString:(NSString *)shortURLString responseData:(NSDictionary *)data 
{
    _blobTweet.shortUrl = [NSURL URLWithString:shortURLString];
    [self postToBlobStorage];
}

- (void)request:(WABitlyHandler *)request failedForLongURL:(NSURL *)url statusCode:(NSInteger)statusCode statusText:(NSString *)statusText
{
    [self displayAlert:statusText];
    [self unlockView];
}

#pragma mark - WALocationControllerDelegate methods

- (void)locationController:(WALocationHandler *)locationController didSelectLocation:(CLLocationCoordinate2D)location
{
    _blobTweet.location = location;
}

#pragma mark - Action methods

- (IBAction)selectImage:(id)sender 
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } 
	
	[self presentModalViewController:imagePicker animated:YES];
}

- (IBAction)tweetBlob:(id)sender 
{
    if (!_bitlyCredential.saved) {
        [self retrieveBitlyInformation];
    } else {
        [self postToBlobStorage];
    }
}

#pragma mark - Private methods

- (void)displayAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tweet Your Blobs"
													message:message
												   delegate:nil 
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)unlockView
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tweet" style:UIBarButtonItemStyleBordered target:self action:@selector(tweetBlob:)];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)lockView
{
    UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:view];
	[view startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)retrieveBitlyInformation 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Setup Bitly Credentials" 
                                                        message:@"Enter your Bitly Crendentials"  
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Done", nil];
    [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    UITextField *nameField = [alertView textFieldAtIndex:0];
    nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameField.placeholder = @"Name"; 
    UITextField *apiKeyField = [alertView textFieldAtIndex:1]; // Capture the Password text field since there are 2 fields
    apiKeyField.placeholder = @"Api Key";
    [alertView show];
}

- (void)postToBlobStorage
{
    if (_blobTweet.isReadyToTweet) {
        [self tweet];
        return;
    }
    
    [self lockView];
    
    WACloudStorageClient *addContainerClient = [WACloudStorageClient storageClientWithCredential:_authenticationCredential];
    
    WABlobContainer *containerToAdd = [[WABlobContainer alloc] initContainerWithName:_blobTweet.containerName];
    containerToAdd.isPublic = _blobTweet.makeContainerPublic;
    containerToAdd.createIfNotExists = YES;
    [addContainerClient addBlobContainer:containerToAdd withCompletionHandler:^(NSError *error) {
        if (error != nil) {
            [self displayAlert:error.localizedDescription];
            [self unlockView];
            return;
        }
        
        WACloudStorageClient *fetchContainerClient = [WACloudStorageClient storageClientWithCredential:_authenticationCredential];
        [fetchContainerClient fetchBlobContainerNamed:containerToAdd.name withCompletionHandler:^(WABlobContainer *container, NSError *error) {
            if (error != nil) {
                [self displayAlert:error.localizedDescription];
                [self unlockView];
                return;
            }
            
            WABlob *blob = [[WABlob alloc] initBlobWithName:_blobTweet.blobName  URL:nil containerName:container.name];
            blob.contentType = @"image/jpeg";
            blob.contentData = UIImageJPEGRepresentation(_blobTweet.image, 1.0); 
            if (_blobTweet.includeLocationData) {
                [blob setValue:_blobTweet.bingLocation forMetadataKey:@"ContentLocation"];
            }
            [blob setValue:@"image/jpeg" forMetadataKey:@"ImageType"];
            WACloudStorageClient *addBlobClient = [WACloudStorageClient storageClientWithCredential:_authenticationCredential];
            [addBlobClient addBlob:blob toContainer:container withCompletionHandler:^(NSError *error) {
                if (error != nil) {
                    [self displayAlert:error.localizedDescription];
                    [self unlockView];
                    return;
                }
                
                WABlobFetchRequest *request = [WABlobFetchRequest fetchRequestWithContainer:container resultContinuation:nil];
                request.prefix = blob.name;
                WACloudStorageClient *fetchBlobClient = [WACloudStorageClient storageClientWithCredential:_authenticationCredential];
                [fetchBlobClient fetchBlobsWithRequest:request usingCompletionHandler:^(NSArray *blobs, WAResultContinuation *resultContinuation, NSError *error){
                    if (error != nil) {
                        [self displayAlert:error.localizedDescription];
                        [self unlockView];
                        return;
                    }
                    WABlob *blobToShorten = [blobs objectAtIndex:0];
                    WABitlyHandler *bitlyHandler = [[WABitlyHandler alloc] initWithLongURL:blobToShorten.URL username:_bitlyCredential.login apiKey:_bitlyCredential.apiKey];
                    [bitlyHandler shortenUrlWithCompletionHandler:^(WABitlyResponse *response, NSError *error) {
                        if (error != nil) {
                            [self displayAlert:error.localizedDescription];
                            [self unlockView];
                            return;
                        }
                        
                        _blobTweet.shortUrl = response.shortURL;
                        // post to twitter
                        [self tweet];
                        [self unlockView];
                    }];
                    
                }];
            }];
        }];
    }];
}

- (void)tweet
{
    Class tweeterClass = NSClassFromString(@"TWTweetComposeViewController");
    
    if(tweeterClass != nil) {   // check for Twitter integration
        // check Twitter accessibility and at least one account is setup
        if([TWTweetComposeViewController canSendTweet]) {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            [tweetViewController addURL:_blobTweet.shortUrl];
            tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
                if(result == TWTweetComposeViewControllerResultDone) {
                    // the user finished composing a tweet
                    [_blobTweet clear];
                    self.navigationItem.leftBarButtonItem.enabled = [_blobTweet isValid];
                    _containerNameTextField.text = @"";
                } else if(result == TWTweetComposeViewControllerResultCancelled) {
                    // the user cancelled composing a tweet
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            };
            
            [self presentViewController:tweetViewController animated:YES completion:nil];
        } else {
            // Twitter is not accessible or the user has not setup an account
            [self displayAlert:NSLocalizedString(@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup.", @"")];
        }
    } else {
        // no Twitter integration; default to third-party Twitter framework
    }
}

@end
