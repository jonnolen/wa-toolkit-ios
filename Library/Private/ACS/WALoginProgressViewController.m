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

#import "WALoginProgressViewController.h"
#import "WALoginRealmPickerTableViewController.h"
#import "WACloudAccessControlClient.h"

@implementation WALoginProgressViewController

- (id)initWithClient:(WACloudAccessControlClient*)client
{
    if ((self = [super initWithNibName:nil bundle:nil])) 
    {
        _client = [client retain];
    }
    return self;
}

- (void)dealloc
{
    [_client release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    UIView* view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
    
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.frame = CGRectMake(100, 140, 25, 25);
    [self.view addSubview:activityView];
    
    [activityView startAnimating];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(135, 140, 320-70, 25)];
    label.text = @"Loading";
    label.textColor = [UIColor darkGrayColor];
    [self.view addSubview:label];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_client getIdentityProvidersWithBlock:^(NSArray* realms, NSError* error)
     {
         if(error)
         {
             //[self dismissModalViewControllerAnimated:YES];
			 UIAlertView* alert;
			 
			 alert = [[UIAlertView alloc] initWithTitle:@"Login" 
												message:[error localizedDescription]
											   delegate:nil 
									  cancelButtonTitle:@"OK" 
									  otherButtonTitles:nil];
			 [alert show];
			 [alert release];
			 return;
         }
         
         [[self retain] autorelease];
         
         UINavigationController* controller = self.navigationController;
         WALoginRealmPickerTableViewController* picker;
         
         picker = [[WALoginRealmPickerTableViewController alloc] initWithRealms:realms];
         controller.viewControllers = [NSArray arrayWithObject:picker];
         [picker release];
     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
