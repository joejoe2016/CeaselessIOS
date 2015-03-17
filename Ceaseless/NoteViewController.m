//
//  NoteViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/12/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//
#import "NoteViewController.h"
#import <AddressBook/AddressBook.h>
#import "AppDelegate.h"
#import "Person.h"

@interface NoteViewController ()

@property (nonatomic, strong) NSMutableArray *namesArray;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UINavigationItem *item;

@end

@implementation NoteViewController

NSString *const kPlaceHolderText = @"Enter note";

- (void)viewDidLoad {
    [super viewDidLoad];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
	self.notesTextView.delegate = self;



		//create navigation bar if there is no navigation controller
	if (!self.navigationController) {
		UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
		navBar.barTintColor = UIColorFromRGBWithAlpha(0x24292f , 0.4);
		NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
												   [UIColor whiteColor], NSForegroundColorAttributeName,
												   [UIFont fontWithName:@"AvenirNext-Medium" size:16.0f],NSFontAttributeName,
												   nil];
		navBar.titleTextAttributes = navbarTitleTextAttributes;
		self.verticalSpaceTopToView.constant = 44;

			//do something like background color, title, etc you self
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClick:)];

		self.item = [[UINavigationItem alloc] initWithTitle:@"Notes"];
		self.item.leftBarButtonItem = cancelButton;
		[navBar pushNavigationItem:self.item animated:NO];

		[self.view addSubview:navBar];

	}
		//if there is a note, just display it and set the right bar button to "Edit"
	if (self.currentNote) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.timeStyle = NSDateFormatterNoStyle;
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		NSDate *date = [self.currentNote valueForKey: @"createDate"];

		self.notesTextView.text = [self.currentNote valueForKey: @"text"];
//		NSString *namesString = [[self.currentNote valueForKey: @"peopleTagged"] componentsJoinedByString:@", "];
		NSSet *peopleTagged = [NSSet setWithObjects: @"Shelli Jackson", @"Virginia Yanoff", nil];
		NSString *namesString = [[peopleTagged allObjects] componentsJoinedByString:@", "];
		self.personsTaggedView.text = namesString;
		self.personsTaggedView.editable = NO;
		self.notesTextView.editable = NO;
		self.tagFriendsButton.enabled = NO;

		UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editMode:)];

		if (!self.navigationController) {
			self.item.title = [dateFormatter stringFromDate:date];
			self.item.rightBarButtonItem = editButton;
		} else {
			self.navigationItem.title = [dateFormatter stringFromDate:date];
			self.navigationItem.rightBarButtonItem = editButton;
		}

	} else {
			//no note passed in, so add a new note, set right bar button to "Save"

		UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];

		if (!self.navigationController) {
			self.item.title = @"Add Note";
			self.item.rightBarButtonItem = saveButton;
		} else {
			self.navigationItem.title = @"Add Note";
			self.navigationItem.rightBarButtonItem = saveButton;

		}
		self.notesTextView.text = kPlaceHolderText;
		self.notesTextView.textColor = [UIColor lightGrayColor];
	}
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) editMode: (id) sender {
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
	self.navigationItem.rightBarButtonItem = saveButton;
	self.personsTaggedView.editable = YES;
	self.notesTextView.editable = YES;
		//bring up keyboard and move cursor to text view
	[self.notesTextView becomeFirstResponder];

}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	if ([[textView text] isEqualToString:kPlaceHolderText]) {
		textView.text = @"";
		textView.textColor = [UIColor whiteColor];
	}

	return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	if ([[textView text] length] == 0) {
		textView.text = kPlaceHolderText;
		textView.textColor = [UIColor lightGrayColor];
	}
	return YES;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
		// Check the segue identifier
	if ([[segue identifier] isEqualToString:@"ShowTaggedPersonPicker"])
		{
		UINavigationController *navController = segue.destinationViewController;
		TaggedPersonPicker *picker = (TaggedPersonPicker *)navController.topViewController;
		picker.delegate = self;
		}
}

#pragma mark - Update Person info

- (void)updatePersonInfo:(NSOrderedSet *)abRecordIDs
{
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

	self.namesArray = [NSMutableArray arrayWithCapacity:abRecordIDs.count];

	for (NSNumber *number in abRecordIDs)
		{
		ABRecordID abRecordID = [number intValue];

		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

		NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);

		[self.namesArray addObject:name];
		}

	CFRelease(addressBook);

	NSString *namesString = [self.namesArray componentsJoinedByString:@", "];

	self.personsTaggedView.text = namesString;
}

#pragma mark - TaggedPersonPickerDelegate protocol conformance

- (void)taggedPersonPickerDidFinish:(TaggedPersonPicker *)taggedPersonPicker
					withABRecordIDs:(NSOrderedSet *)abRecordIDs
{
	[self updatePersonInfo:abRecordIDs];

	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker
{
	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)saveButtonPressed:(id)sender {

//	NSMutableSet *mutablePeopleSet = [NSMutableSet alloc];
//	for (NSString *name in self.namesArray) {
//       use the name to get a Person Object
//       [mutablePeopleSet addObject: Person Object];
//	}
//	NSSet *peopleTaggedSet = [[NSSet alloc] initWithSet: mutablePeopleSet];
	NSError *error = nil;

	Note *note = [self containsItem:[self.currentNote valueForKey: @"createDate"]];
	if (note) {
			//if the object is found, update its fields
			//		[[self.fetchedObjects objectAtIndex:0] setValue: dataForPost.title forKey: @"title"];
		[note setValue: self.notesTextView.text forKey: @"text"];
		[note setValue: [NSDate date] forKey: @"lastUpdatedDate"];
		//	[note setValue: peopleTaggedSet forKey:@"peopleTagged"];


	} else {
	NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
		[newManagedObject setValue: [NSDate date] forKey: @"createDate"];
		[newManagedObject setValue: self.notesTextView.text forKey: @"text"];
		[newManagedObject setValue: [NSDate date] forKey: @"lastUpdatedDate"];
	//	[newManagedObject setValue: peopleTaggedSet forKey:@"peopleTagged"];
		}
	if (![self.managedObjectContext save: &error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}

//	[self listAll];
	if (self.delegate) {
		[self.delegate noteViewControllerDidFinish:self];
	} else {
		[self performSegueWithIdentifier:@"UnwindSegue" sender: self];

	}
}
- (Note*) containsItem: (NSDate *) createDate {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSError *error = nil;

	NSPredicate *pred = [NSPredicate predicateWithFormat:@"createDate == %@", createDate];

	[fetchRequest setPredicate:pred];

		//    NSLog(@"entity retrieved is %@", entity);

	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

	if (fetchedObjects == nil) {
			// Handle the error
		NSLog (@"fetch error");
	}

	if ([fetchedObjects count] == 0) {
			//        NSLog (@"no mediatItemUser objects fetched");
		return nil;
	} else {
			// if there is an object, need to return it
		return [fetchedObjects objectAtIndex:0];
	}

}
#pragma mark - Target-action methods

	// Action receiver for the clicking of Done button
- (IBAction)doneClick:(id)sender
{

	[self.delegate noteViewControllerDidFinish:self];
}

	// Action receiver for the clicking of Cancel button
- (IBAction)cancelClick:(id)sender
{
	if (self.delegate) {
		[self.delegate noteViewControllerDidCancel:self];
	} else {
		[self performSegueWithIdentifier:@"UnwindSegue" sender: self];
	}
}
- (void) listAll {
		// Test listing all tagData from the store
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
	NSError * error = nil;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
											  inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];


	NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (id managedObject in fetchedObjects) {

		NSLog(@"create date: %@", [managedObject valueForKey: @"createDate"]);
		NSLog(@"text: %@", [managedObject valueForKey: @"text"]);
		NSLog(@"last update date: %@", [managedObject valueForKey: @"lastUpdatedDate"]);

	}
}
@end