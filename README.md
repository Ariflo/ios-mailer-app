# Addressable: Looking Glass

The mobile (iOS) application extension of the [Addressable Web App](https://live.addressable.app).

<p float="left">
<img src="AppImages/mailing_list.gif" width="250" height="550" />
<img src="AppImages/mailing_detail.gif" width="250" height="550" />
<img src="AppImages/audience_selection.gif" width="250" height="550" />
</p>


## Description

This repository houses Addressable's mobile iOS suite that permits Addressable users to:

- Build, track, edit, and send 'Radius' mailing campaigns
- Recieve push notificaitons related to mailing status (ie. recipient list curation, mailing status)
- Make and recieve related incoming lead calls and messages, along with handling any Twilio smart number telephoney related features
- Tag incoming leads (ie. Spam, Strong or Fair lead)
- Update user preferences (ie. change handwritng styles, top-up token count, invite teammates, edit address)
- Send feedback

See [testing script](https://coda.io/d/Team-Docs_d3mPNt8HIPw/Mobile-App-Testing-Script_sua8H#_luZC1) for a breakdown of all application features.

## Getting Started

### Dependencies

* Xcode 13.0
* min iOS / device version: iOS 13.0 / iPhone 6s
* Install [Git LFS](https://git-lfs.github.com)
* Install [Swift-lint](https://github.com/realm/SwiftLint)
* Install [audience-service](https://github.com/Addressable/audience_service) for local recipient list curation
* Install [illustrator-job-queue](https://github.com/Addressable/illustrator_job_queue) for mailing image preview creation
* Install [Adobe Illustrator](https://www.adobe.com/products/illustrator/free-trial-download.html) ***License Required***
* Install the Latest version of [Addressable API](https://www.notion.so/conversionrobots/Local-Dev-Machine-Setup-3cb90d7e23aa46b489a0cefd314fa42e) 

### Installing

* `git clone git@github.com:Addressable/looking_glass.git`
* Open Xcode click `File` > `Open` > `[your_path_to_looking_glass_repo]/Addressable.xcodeproj`

### Build and Run App

* Set Targets to `Debug` > `iPhone_6s_or_above_simulator`
* `Cmd-B` to Build 
* `Cmd-R` to Run
* Sign-In to App w/ [Addressable Login](https://live.addressable.app/signup) Credentials

## Setup Tips & Tricks

* Install [oh-my-zsh](https://ohmyz.sh) to make terminal command line usage quick and easy
* Install [Homebrew](https://brew.sh) to make adding dependencies to your Mac easy
* Add the following to your `.Bash_Profile` or `.zshrc` (Please take note of differing `./PATHs`):

```
###### Run inside of illustrator_job_queue ######
run_layout_engine() {
   python layout_engine.py -e dev
}
###### Run inside of audience-service ######
run_datatree_searches() {
   python main.py -e dev_ari
}

run_audience_service() {
   ~/addressable/audience_service && source venv/bin/activate
}

run_illustrator() {
   ~/addressable/illustrator_job_queue && source venv/bin/activate && cd python 
}

sidekick() {
 ~/addressable/letters && Bundle exec sidekiq -C config/sidekiq.yml
}

run_addressable_app(){
 ~/addressable/letters && bundle install && bundle exec rails db:migrate RAILS_ENV=development && bundle exec rails s
}

run_ngrok() {
    addressable/ngrok http -subdomain=addressabledev 3000
}

open_new_tab() {
osascript -e 'tell application "Terminal" to activate' \
  -e 'tell application "System Events" to tell process "Terminal" to keystroke "t" using command down' \
  -e 'tell application "Terminal" to do script "'$1'" in selected tab of the front window'
}

start_up_addressable() {
  open_new_tab run_ngrok && open_new_tab run_addressable_app && sleep 2 && open_new_tab sidekick && sleep 2 && open_new_tab run_illustrator && sleep 2 && open_new_tab run_audience_service && open_new_tab ~/addressable/looking_glass && exit
}
```
* Run `start_up_addressable()` in a new Terminal shell to immediately get a working local instance of the Addressable local API running: [See Working Demo](https://youtu.be/ps6QPAr1oao)

## Certification Renwal (circa Mar. 2022)

### *Things to Note* 

* As of this writing there is no "renewing" an Apple certificate, you must create a new one to replace the old one. 

* The steps are the same for renewing all Apple certificates (VOIP, Sandbox, Development, Distribution etc.)

* You do * NOT * need to revoke or remove the original / expiring certificates. If you do, only do so after updating all third-party services with the new certificate.

1 - Login to the [Apple Development Portal](https://developer.apple.com/account/resources/certificates/list), navigate to the "Certificates, Identifiers & Profiles" page.

2 - Tap on the (+) icon.

3 - Select the Software or Service Certificate you desire to create.

4 - Select the related App ID you wish to associate with the certificate.

5 - Follow the [steps to create a new certification request](https://help.apple.com/developer-account/#/devbfa00fef7) on your Mac.

6 - Upload the `.certSigningRequest` file that you just created.

7 - Click the download button to get the `.cer` file from Apple.

8 - Double-click the downloaded `.cer` file on your Mac to add it to your keychain.

9 - Find the newly added certificate in the `Keychain Access Application` window and right-click it to export as `.p12` and create a secure password (store in `1password` or some password manager).

10 - Use the newly created `.p12` certificate to distribute to all third-party services and servers that'll require it for authorization.

### Upload APN Certificate to AWS SNS

1 - Go to Amazon's [AWS SNS](https://us-west-1.console.aws.amazon.com/sns/v3/home?region=us-west-1#/mobile/push-notifications) page, click on the "Push Notifications" tab to see the list of your `Platform Applications`.

2 - Select the application that needs renewed credentials.

3 - Select the `Edit` button.

4 - Select `Certificate` under the "Authentication Method" heading.

5 - Choose the `.p12` file you created locally and provide the secure password.

6 - Save Changes.

### Upload APN Certificate to Twilio

1 - Go to Twilio's [Mobile Push Credentials](https://console.twilio.com/us1/develop/notify/try-it-out?frameUrl=%2Fconsole%2Fnotify%2Fcredentials%2Fcreate%3Fx-target-region%3Dus1) page.

2 - Select the application that needs renewed credentials.

3 - Keep this page open on your browser and open a new `Terminal` shell. We need to extract the certificate key and private key from the `.p12`. 

4 - Enter the following command into your terminal to create the `cert.pem`: <br>```openssl pkcs12 -in [PATH_TO_YOUR_.p12] -nokeys -out cert.pem -nodes```.

5 - Enter the following command into your terminal to create the `key.pem`: <br>```openssl pkcs12 -in [PATH_TO_YOUR_.p12] -nocerts -out key.pem -nodes```.

6 - Run the following command into your terminal: <br>```openssl rsa -in key.pem -out key.pem```.

7 - Run the following command into your terminal: <br> ```open -a TextEdit [PATH_TO_YOUR_cert.pem]```.

9 - Copy and paste everything within and including the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` boundaries to [Mobile Push Credentials](https://console.twilio.com/us1/develop/notify/try-it-out?frameUrl=%2Fconsole%2Fnotify%2Fcredentials%2Fcreate%3Fx-target-region%3Dus1) page under `Certificate`.

10 - Run the following command in your terminal: <br> ```open -a TextEdit [PATH_TO_YOUR_key.pem]```.

11 - Copy and paste everything within and including the `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` boundaries to [Mobile Push Credentials](https://console.twilio.com/us1/develop/notify/try-it-out?frameUrl=%2Fconsole%2Fnotify%2Fcredentials%2Fcreate%3Fx-target-region%3Dus1) page under `Private Key`.

12 - Save Changes.


## Architecture

This application is developed using Apple's Swift / Swift UI Framework. The application is broken down into three environments, each connecting to the cooresponding Addressable API environment:

* `Release` - API: https://live.addressable.app/api/v1
* `Sandbox` - API: https://sandbox.addressable.app/api/v1
* `Debug :: Staging` - API: http://localhost:3000/api/v1 :: http://`ngork_tunnel`/api/v1 
	* For local ***physical device*** testing, especially when testing telephoney related features like phone calls it helps to use [ngork](https://ngrok.com/product) to setup a web tunnel to your local running instance of the API.

## System Design Pattern

The adopted design pattern is [Model-View-ViewModel (MVVM)](https://www.raywenderlich.com/4161005-mvvm-with-combine-tutorial-for-ios) using the [Combine framework](https://developer.apple.com/documentation/combine) to manage state. The idea being to separate the UI logic from the business logic in order to make apps easier to develop and test.

In short the design pattern helps to guide the relationships between three components: `View`, `ViewModel`, `Model` in the following way:

* The `View` has a reference to the `ViewModel`, but not vice-versa.
* The `ViewModel` has a reference to the `Model`, but not vice-versa.
* The `View` has no reference to the `Model` or vice-versa.

General rules to follow when developing a new `View` in the application:

* Keep the `View` lightweight; consisting only of UI / appearance related code (ie. text size, background color, spacing)
* Place and name all View files in `Addressable/Views/[related_view_group]/[view_name]View`
* Place and name all ViewModel files in `Addressable/ViewModels/[view_name]ViewModel`
* Place all Model files in `Addressable/Models/[model_name]`

## Code Format / Linter
This application follows the formating set by [Swift-lint](https://github.com/realm/SwiftLint)

To run linter and auto format your files run the following on your command line:

```
swiftlint autocorrect --format --path [PATH_TO_LOOKING_GLASS]/looking_glass/Addressable
```
### General Formatting Rules
* Name all varibles, classes, and files using `CamelCase` style.
* Use common sense with file placement (ie. util classes in `Utiles` group, service classes in `Services` group, core data models in `CoreDataModels` group etc.).
* Designate files sections using Xcode `// MARK: - ` denotation to make it easier for differentiate sections of a file.

## Code Clean Up Required
The following are some of the TODO's where some code clean up and refactoring is required: 

* **Addressable.swift**: 
	* `class Application` should be renamed to `AppDelegate` waiting on this [Swift Lint Issue](https://github.com/realm/SwiftLint/issues/2786) to get resolved. 
	* Currently using deprecated `keyWindow` to display permissions alert at initial application invocation. Should be removed when mobile app sign up flow is designed and decided on.
	* `currentView` and `selectMailing` application level varibles should be revisited when Sphere and Farming Mailings are added to the app.

* **ComposeRadiusTopicSelectionView.swift** & **MessageTemplateSelectionView.swift**: 
	* These files need to be broken down into simple reusable view components for `Multi-Touch Topic Selection`, `Message Template Selection`, and `Merge Tag Variable` handling. See `MailingRecipientView` and `MailingDetailView` as potential examples to go off of.

* **MailingDetialView.swift** & **ComposeRadiusView.swift**: : 
	* The data flow of these files should probably be revisited.

## Testing

TBD

## Application File Structure - circa 10.2021
```
.
|____ViewModels
| |____ConfirmAndSendMailingViewModel.swift
| |____ComposeRadiusViewModel.swift
| |____CallsViewModel.swift
| |____SelectAudienceViewModel.swift
| |____PreviewViewModel.swift
| |____EditReturnAddressViewModel.swift
| |____MailingDetailViewModel.swift
| |____MessageTemplateSelectionViewModel.swift
| |____MessagesViewModel.swift
| |____TagIncomingLeadViewModel.swift
| |____SendFeedbackViewModel.swift
| |____MailingCoverImagePagerViewModel.swift
| |____DashboardViewModel.swift
| |____CampaignsViewModel.swift
| |____MailingCoverImageGalleryViewModel.swift
| |____SignInViewModel.swift
| |____MailingRecipientsListViewModel.swift
| |____ProfileViewModel.swift
|____Campaigns.xcdatamodeld
| |____Campaigns.xcdatamodel
| | |____contents
|____AnalyticEvents.xcdatamodeld
| |____AnalyticEvents.xcdatamodel
| | |____contents
|____.DS_Store
|____Assests.xcassets
| |____Contents.json
| |____AddressableAssests.imageset
| | |____Contents.json
| | |____iu.png
|____User.xcdatamodeld
| |____User.xcdatamodel
|____AddressableApp.swift
|____Assets.xcassets
| |____.DS_Store
| |____BlankCard.imageset
| | |____card.png
| | |____Contents.json
| |____EyeOpen.imageset
| | |____EyeOpen.png
| | |____Contents.json
| |____EyeClose.imageset
| | |____Contents.json
| | |____EyeClose.png
| |____AppIcon.appiconset
| | |____iPhone-20@3x.png
| | |____iPad-29@1x.png
| | |____iPad-20@2x.png
| | |____iPad-83.5@2x.png
| | |____iPhone-20@2x.png
| | |____iPhone-29@1x.png
| | |____iPad-40@1x.png
| | |____iPad-76@1x.png
| | |____iPhone-40@2x.png
| | |____iPhone-40@3x.png
| | |____Contents.json
| | |____iPad-40@2x.png
| | |____iPad-76@2x.png
| | |____iPhone-60@3x.png
| | |____iPhone-29@2x.png
| | |____AppStore-1024@1x.png
| | |____iPad-20@1x.png
| | |____iPad-29@2x.png
| | |____iPhone-29@3x.png
| | |____iPhone-60@2x.png
| |____AccentColor.colorset
| | |____Contents.json
| |____StyleSamples.imageset
| | |____style_samples.png
| | |____Contents.json
| |____AppIcon-Dev.appiconset
| | |____Icon-Addressable-40x40@3x.png
| | |____Icon-Addressable-29x29@2x.png
| | |____Icon-Addressable-60x60@2x.png
| | |____Icon-Addressable-60x60@3x.png
| | |____Icon-Addressable-29x29@3x.png
| | |____Icon-Addressable-40x40@2x.png
| | |____1024x1024.png
| | |____Icon-Addressable-20x20@2x.png
| | |____Icon-Addressable-20x20@3x.png
| | |____Contents.json
| | |____Icon-Addressable-29x29@1x.png
| |____ZippyIcon.imageset
| | |____50ca91aa-7cd6-4df5-8e3b-2ab6486db33f.png
| | |____Contents.json
| |____Contents.json
|____Models
| |____Analytics.swift
| |____Authorization.swift
| |____MessageTemplate.swift
| |____CallManager.swift
| |____Handwriting.swift
| |____.DS_Store
| |____DataTreeSearch.swift
| |____MailingCoverImage.swift
| |____PersistentContainer.swift
| |____Recipient.swift
| |____Message.swift
| |____IncomingLead.swift
| |____CustomNote.swift
| |____MultiTouchTopic.swift
| |____Mailing.swift
| |____CoreDataModels
| | |____AnalyticEvent+CoreDataProperties.swift
| | |____PersistedCampaign+CoreDataClass.swift
| | |____AnalyticEvent+CoreDataClass.swift
| | |____PersistedCampaign +CoreDataProperties.swift
| |____Account.swift
| |____Feedback.swift
|____Preview Content
| |____Preview Assets.xcassets
| | |____Contents.json
|____Mailings.xcdatamodeld
| |____Mailings.xcdatamodel
|____Utilities
| |____NumberUtils.swift
| |____EnumUtil.swift
| |____JsonUtil.swift
| |____DateUtil.swift
| |____BordersUtils.swift
| |____KeychainServiceUtil.swift
| |____ColorsUtil.swift
| |____PermissionsUtil.swift
| |____FontUtils.swift
| |____AnalyticsTracker.swift
| |____DictionaryUtil.swift
| |____UIDeviceUtil.swift
| |____SliderUtils.swift
| |____UtilityProvider.swift
| |____ArrayUtil.swift
| |____StringsUtil.swift
|____Addressable.entitlements
|____Views
| |____DashboardView.swift
| |____ViewsUtilities
| | |____MultilineTextView.swift
| | |____SegmentedControlIconOptionView.swift
| | |____CloneMailingViewModel.swift
| | |____AddMenuItem.swift
| | |____MessageAlert.swift
| | |____PreviewView.swift
| | |____ListSeparatorStyle.swift
| | |____CustomHeader.swift
| | |____DetectScrollView.swift
| | |____AdaptsToKeyboard.swift
| | |____CheckView.swift
| | |____SliderView.swift
| | |____CustomSegmentedPickerView.swift
| | |____TextFieldModifier.swift
| | |____RefreshableScrollView.swift
| | |____Popup.swift
| |____AppView.swift
| |____RadiusMailingViews
| | |____ComposeRadiusSelectLocationView.swift
| | |____TargetCriteriaSliderView.swift
| | |____ComposeRadiusView.swift
| | |____ComposeRadiusTopicSelectionView.swift
| | |____TargetCriteriaMenuView.swift
| | |____ComposeRadiusConfirmSendView.swift
| | |____ComposeRadiusListConfirmationView.swift
| | |____ComposeRadiusCoverImageSelectionView.swift
| | |____GoogleMapsView.swift
| | |____ComposeRadiusAudienceConfirmationView.swift
| |____MailingRecipientsListView.swift
| |____CallViews
| | |____AddressableCallView.swift
| | |____KeyPadView.swift
| | |____CallListView.swift
| | |____TagIncomingLeadView.swift
| | |____CallListSectionHeaderView.swift
| |____ProfileSettingViews
| | |____ProfileView.swift
| | |____ProfileSettingSectionView.swift
| | |____EditUserAddressView.swift
| |____SignInView.swift
| |____DashboardViews
| | |____MailingCardItemView.swift
| | |____DashboardView.swift
| | |____CalendarTileView.swift
| | |____CampaignsFilterBoxesView.swift
| | |____NavigationMenuView.swift
| | |____CampaignSectionHeaderView.swift
| | |____SendFeedbackView.swift
| | |____CampaignsView.swift
| | |____CampaignsListView.swift
| | |____MessageTemplateSelectionView.swift
| |____MailingCoverArtView.swift
| |____MessageViews
| | |____MessageListView.swift
| | |____ContentMessageView.swift
| | |____MessageChatView.swift
| | |____MessageView.swift
| |____MailingDetailViews
| | |____MailingImagePreviewView.swift
| | |____CloneMailingView.swift
| | |____ConfirmAndSendMailingView.swift
| | |____EditReturnAddressView.swift
| | |____SelectAudienceView.swift
| | |____MailingCoverImagePagerView.swift
| | |____MailingDetailView.swift
| | |____MailingCoverImageGalleryView.swift
|____Info.plist
|____Services
| |____CallService.swift
| |____ApiService.swift
| |____DependencyProvider.swift
| |____ServiceProvider.swift

```
## Authors

Contributors

* [Arian Flores](https://www.linkedin.com/in/arianflores/)

## Version History (Major.Minor.Patch)
* 0.1.5
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/45)
* 0.1.4
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/42)
* 0.1.3
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/38)
* 0.1.2
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/35)
* 0.1.1
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/33)
* 0.0.2
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/25)
* 0.0.1
    * Various bug fixes and optimizations
    * See [commit change](https://github.com/Addressable/looking_glass/pull/24)
* 0.0.0
    * Initial Release

## License

©2021 Addressablemail.com

## Acknowledgments

* [letters-repo](https://github.com/Addressable/letters)
* [Testing Script](https://coda.io/d/Team-Docs_d3mPNt8HIPw/Mobile-App-Testing-Script_sua8H#_luZC1)
* [Ray Wenderlich - MVVM w/ Combine](https://www.raywenderlich.com/4161005-mvvm-with-combine-tutorial-for-ios)
* [ngork](https://ngrok.com/product)
* [oh-my-zsh](https://ohmyz.sh)
* [Swift-lint](https://github.com/realm/SwiftLint)
* [Twilio iOS SDK](https://www.twilio.com/docs/voice/sdks/ios)
* [Renew Apple Push Notifications](https://dontpaniclabs.com/blog/post/2021/04/13/renewing-your-apple-push-notification-ssl-certificate/)
* [Twilio iOS SDK Quick Guide](https://www.twilio.com/docs/voice/sdks/ios/get-started)
