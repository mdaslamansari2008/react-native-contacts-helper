//
//  RCTContactHelperIOS.h
//  RCTContactHelperIOS
//
//  Created by aslam on 20/02/18.
//  Copyright © 2018 aslam. All rights reserved.
//

//#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

@interface RCTContactHelperIOS : NSObject <RCTBridgeModule, CNContactViewControllerDelegate>

@end
