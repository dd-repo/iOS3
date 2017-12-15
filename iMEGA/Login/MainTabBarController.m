#import "MainTabBarController.h"

#import "CallViewController.h"
#import "MEGAProviderDelegate.h"
#import "MessagesViewController.h"
#import "MEGAChatCall+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

@interface MainTabBarController () <UITabBarControllerDelegate, MEGAGlobalDelegate, MEGAChatCallDelegate>

@property (nonatomic, strong) MEGAProviderDelegate *megaProviderDelegate;

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *defaultViewControllersMutableArray = [[NSMutableArray alloc] initWithCapacity:5];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateInitialViewController]];
    
    for (NSInteger i = 0; i < [defaultViewControllersMutableArray count]; i++) {
        UITabBarItem *tabBarItem = [[defaultViewControllersMutableArray objectAtIndex:i] tabBarItem];
        switch (tabBarItem.tag) {
            case CLOUD:
                [tabBarItem setImage:[[UIImage imageNamed:@"cloudDriveIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"cloudDriveSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                break;
                
            case PHOTOS:
                [tabBarItem setImage:[[UIImage imageNamed:@"cameraUploadsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"cameraUploadsSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
                break;
                
            case SHARES:
                [tabBarItem setImage:[[UIImage imageNamed:@"sharedItemsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"sharedItemsSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"shared", nil)];
                break;
                
            case MYACCOUNT:
                [tabBarItem setImage:[[UIImage imageNamed:@"myAccountIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"myAccountSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"myAccount", nil)];
                break;
                
            case CHAT:
                [tabBarItem setImage:[[UIImage imageNamed:@"chatIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"chatSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"chat", @"Chat section header");
                break;
        }
    }
    
    self.viewControllers = defaultViewControllersMutableArray;
    
    [self.view setTintColor:[UIColor mnz_redD90007]];
    
    [self setDelegate:self];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    [self setBadgeValueForChats];
    [self setBadgeValueForIncomingContactRequests];
    
    if (@available(iOS 10.0, *)) {
        _megaCallManager = [[MEGACallManager alloc] init];
        _megaProviderDelegate = [[MEGAProviderDelegate alloc] initWithMEGACallManager:self.megaCallManager];
    }
}

- (BOOL)shouldAutorotate {
    if ([self.selectedViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.selectedViewController shouldAutorotate];
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([self.selectedViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
            if ([self.selectedViewController isEqual:self.moreNavigationController]) {
                return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
            }
            
            return [self.selectedViewController supportedInterfaceOrientations];
        }
        
        if ([self.selectedViewController isEqual:self.moreNavigationController]) {
            return UIInterfaceOrientationMaskAll;
        }
        return [self.selectedViewController supportedInterfaceOrientations];
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

#pragma mark - Private

- (void)setBadgeValueForIncomingContactRequests {
    MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
    long incomingContacts = incomingContactsLists.size.longLongValue;
    NSString *badgeValue = incomingContacts ? [NSString stringWithFormat:@"%ld", incomingContacts] : nil;
    [self setBadgeValue:badgeValue tabPosition:MYACCOUNT];
}

- (void)setBadgeValueForChats {
    NSInteger unreadChats = ([MEGASdkManager sharedMEGAChatSdk] != nil) ? [[MEGASdkManager sharedMEGAChatSdk] unreadChats] : 0;
    
    NSString *badgeValue = unreadChats ? [NSString stringWithFormat:@"%ld", unreadChats] : nil;
    [self setBadgeValue:badgeValue tabPosition:CHAT];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = unreadChats;
}

- (void)setBadgeValue:(NSString *)badgeValue tabPosition:(NSInteger)tabPosition {
    if (tabPosition < self.tabBar.items.count) {
        [[self.viewControllers objectAtIndex:tabPosition] tabBarItem].badgeValue = badgeValue;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self setBadgeValueForIncomingContactRequests];
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    if (item.changes == MEGAChatListItemChangeTypeUnreadCount) {
        [self setBadgeValueForChats];
        if ([[self.selectedViewController visibleViewController] isKindOfClass:[MessagesViewController class]]) {
            MessagesViewController *messagesViewController = (MessagesViewController *)[self.selectedViewController visibleViewController];
            if (messagesViewController.chatRoom.chatId != item.chatId) {
                [messagesViewController updateUnreadLabel];
            }
        }        
    }
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    switch (call.status) {
        case MEGAChatCallStatusInitial:
            break;
            
        case MEGAChatCallStatusHasLocalStream:
            break;
            
        case MEGAChatCallStatusRequestSent:
            break;
            
        case MEGAChatCallStatusRingIn: {
            MEGAChatRoom *chatRoom = [api chatRoomForChatId:call.chatId];
            if (@available(iOS 10.0, *)) {
                NSUUID *uuid = [[NSUUID alloc] init];
                call.uuid = uuid;
                                
                uint64_t peerHandle = [chatRoom peerHandleAtIndex:0];
                NSString *email = [chatRoom peerEmailByHandle:peerHandle];
                
                [self.megaProviderDelegate reportIncomingCall:call hasVideo:call.hasRemoteVideo email:email];
            } else {
                CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
                callVC.chatRoom  = chatRoom;
                callVC.videoCall = call.hasRemoteVideo;
                callVC.callType = CallTypeIncoming;
                [[UIApplication mnz_visibleViewController] presentViewController:callVC animated:YES completion:nil];
            }
            break;
        }
            
        case MEGAChatCallStatusJoining:
            break;
            
        case MEGAChatCallStatusInProgress:
            break;
        case MEGAChatCallStatusTerminating:
            break;
        case MEGAChatCallStatusDestroyed:
            if (@available(iOS 10.0, *)) {
                [self.megaCallManager endCall:call];
            }            
            break;
            
        default:
            break;
    }
}

@end
