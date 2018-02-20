//
//  RCTContactHelperIOS.m
//  RCTContactHelperIOS
//
//  Created by aslam on 20/02/18.
//  Copyright © 2018 aslam. All rights reserved.
//

#import "RCTContactHelperIOS.h"
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation RCTContactHelperIOS{
    CNContactStore * contactStore;
}

RCT_EXPORT_MODULE();

-(NSDictionary *) constantsToExport {
    return  @{@"Greeting":@"Hello world from native"};
}

//RCT_EXPORT_METHOD(squareMe:(int)number:(RCTResponseSenderBlock)callback){
RCT_EXPORT_METHOD(squareMe:(RCTResponseSenderBlock)callback){
    // callback(@[[NSNull null], @"Aslam from native component"]);
    callback(@[@"error from aslam", @"Aslam from native component"]);
}

RCT_EXPORT_METHOD(getValue:(NSString *)input callback:(RCTResponseSenderBlock)callback){
  //  NSLog(input);
    callback(@[@"Error filed", @"Result section"]);
}

RCT_EXPORT_METHOD(getAllContacts:(RCTResponseSenderBlock)callback){
    [self getAllContactsDetails:callback];
}

-(void)getAllContactsDetails:(RCTResponseSenderBlock) callback {
    
    CNContactStore* contactStore = [self contactsStore:callback];
    if(!contactStore){
        return;
    }
    
    [self retrieveContactsFromAddressBook:contactStore withThumbnails:NO withCallback:callback];
    
}


-(CNContactStore*) contactsStore: (RCTResponseSenderBlock)callback {
    if(!contactStore) {
        CNContactStore* store = [[CNContactStore alloc] init];
        
        if(!store.defaultContainerIdentifier) {
            NSLog(@"warn - no contact store container id");
            
            CNAuthorizationStatus authStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
            if (authStatus == CNAuthorizationStatusDenied || authStatus == CNAuthorizationStatusRestricted){
                callback(@[@"denied", [NSNull null]]);
            } else {
                callback(@[@"undefined", [NSNull null]]);
            }
            
            return nil;
        }
        
        contactStore = store;
    }
    
    return contactStore;
}



-(void) retrieveContactsFromAddressBook:(CNContactStore*)contactStore
                         withThumbnails:(BOOL) withThumbnails
                           withCallback:(RCTResponseSenderBlock) callback
{
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    NSError* contactError;
    [contactStore containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[contactStore.defaultContainerIdentifier]] error:&contactError];
    
    
    NSMutableArray *keysToFetch = [[NSMutableArray alloc]init];
    [keysToFetch addObjectsFromArray:@[
                                       CNContactEmailAddressesKey,
                                       CNContactPhoneNumbersKey,
                                       CNContactFamilyNameKey,
                                       CNContactGivenNameKey,
                                       CNContactMiddleNameKey,
                                       CNContactPostalAddressesKey,
                                       CNContactOrganizationNameKey,
                                       CNContactJobTitleKey,
                                       CNContactImageDataAvailableKey,
                                       CNContactBirthdayKey
                                       ]];
    
    if(withThumbnails) {
        [keysToFetch addObject:CNContactThumbnailImageDataKey];
    }
    
    CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
    BOOL success = [contactStore enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
        NSDictionary *contactDict = [self contactToDictionary:contact withThumbnails:withThumbnails];
        [contacts addObject:contactDict];
    }];
    
    callback(@[[NSNull null], contacts]);
}



-(NSDictionary*) contactToDictionary:(CNContact *) person
                      withThumbnails:(BOOL)withThumbnails
{
    NSMutableDictionary* output = [NSMutableDictionary dictionary];
    
    NSString *recordID = person.identifier;
    NSString *givenName = person.givenName;
    NSString *familyName = person.familyName;
    NSString *middleName = person.middleName;
    NSString *company = person.organizationName;
    NSString *jobTitle = person.jobTitle;
    NSDateComponents *birthday = person.birthday;
    
    [output setObject:recordID forKey: @"recordID"];
    
    if (givenName) {
        [output setObject: (givenName) ? givenName : @"" forKey:@"givenName"];
    }
    
    if (familyName) {
        [output setObject: (familyName) ? familyName : @"" forKey:@"familyName"];
    }
    
    if(middleName){
        [output setObject: (middleName) ? middleName : @"" forKey:@"middleName"];
    }
    
    if(company){
        [output setObject: (company) ? company : @"" forKey:@"company"];
    }
    
    if(jobTitle){
        [output setObject: (jobTitle) ? jobTitle : @"" forKey:@"jobTitle"];
    }
    
    
    if (birthday) {
        if (birthday.month != NSDateComponentUndefined && birthday.day != NSDateComponentUndefined) {
            //months are indexed to 0 in JavaScript (0 = January) so we subtract 1 from NSDateComponents.month
            if (birthday.year != NSDateComponentUndefined) {
                [output setObject:@{@"year": @(birthday.year), @"month": @(birthday.month - 1), @"day": @(birthday.day)} forKey:@"birthday"];
            } else {
                [output setObject:@{@"month": @(birthday.month - 1), @"day":@(birthday.day)} forKey:@"birthday"];
            }
        }
    }
    
    //handle phone numbers
    NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
    
    for (CNLabeledValue<CNPhoneNumber*>* labeledValue in person.phoneNumbers) {
        NSMutableDictionary* phone = [NSMutableDictionary dictionary];
        NSString * label = [CNLabeledValue localizedStringForLabel:[labeledValue label]];
        NSString* value = [[labeledValue value] stringValue];
        
        if(value) {
            if(!label) {
                label = [CNLabeledValue localizedStringForLabel:@"other"];
            }
            [phone setObject: value forKey:@"number"];
            [phone setObject: label forKey:@"label"];
            [phoneNumbers addObject:phone];
        }
    }
    
    [output setObject: phoneNumbers forKey:@"phoneNumbers"];
    //end phone numbers
    
    //handle emails
    NSMutableArray *emailAddreses = [[NSMutableArray alloc] init];
    
    for (CNLabeledValue<NSString*>* labeledValue in person.emailAddresses) {
        NSMutableDictionary* email = [NSMutableDictionary dictionary];
        NSString* label = [CNLabeledValue localizedStringForLabel:[labeledValue label]];
        NSString* value = [labeledValue value];
        
        if(value) {
            if(!label) {
                label = [CNLabeledValue localizedStringForLabel:@"other"];
            }
            [email setObject: value forKey:@"email"];
            [email setObject: label forKey:@"label"];
            [emailAddreses addObject:email];
        } else {
            NSLog(@"ignoring blank email");
        }
    }
    
    [output setObject: emailAddreses forKey:@"emailAddresses"];
    //end emails
    
    //handle postal addresses
    NSMutableArray *postalAddresses = [[NSMutableArray alloc] init];
    
    for (CNLabeledValue<CNPostalAddress*>* labeledValue in person.postalAddresses) {
        CNPostalAddress* postalAddress = labeledValue.value;
        NSMutableDictionary* address = [NSMutableDictionary dictionary];
        
        NSString* street = postalAddress.street;
        if(street){
            [address setObject:street forKey:@"street"];
        }
        NSString* city = postalAddress.city;
        if(city){
            [address setObject:city forKey:@"city"];
        }
        NSString* state = postalAddress.state;
        if(state){
            [address setObject:state forKey:@"state"];
        }
        NSString* region = postalAddress.state;
        if(region){
            [address setObject:region forKey:@"region"];
        }
        NSString* postCode = postalAddress.postalCode;
        if(postCode){
            [address setObject:postCode forKey:@"postCode"];
        }
        NSString* country = postalAddress.country;
        if(country){
            [address setObject:country forKey:@"country"];
        }
        
        NSString* label = [CNLabeledValue localizedStringForLabel:labeledValue.label];
        if(label) {
            [address setObject:label forKey:@"label"];
            
            [postalAddresses addObject:address];
        }
    }
    
    [output setObject:postalAddresses forKey:@"postalAddresses"];
    //end postal addresses
    
    [output setValue:[NSNumber numberWithBool:person.imageDataAvailable] forKey:@"hasThumbnail"];
//    if (withThumbnails) {
//        [output setObject:[self getFilePathForThumbnailImage:person recordID:recordID] forKey:@"thumbnailPath"];
//    }
    
    return output;
}

@end
