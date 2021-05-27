//
//  AppView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct AppView: View {
    @EnvironmentObject var app: Application
    @State var displayIncomingLeadSurvey: Bool = false

    var body: some View {
        if KeyChainServiceUtil.shared[userBasicAuthToken] != nil {
            if app.displayCallView {
                AddressableCallView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher()))
                    .environmentObject(app)
                    .navigationBarHidden(true)
            } else if app.displayComposeRadiusMailing {
                ComposeRadiusMailingView(
                    viewModel: ComposeRadiusMailingViewModel(
                        selectedRadiusMailing: app.selectedRadiusMailing)
                ).environmentObject(app)
            } else {
                TabView {
                    MailingsView(
                        viewModel: MailingsViewModel(addressableDataFetcher: AddressableDataFetcher())
                    )
                    .environmentObject(app)
                    .navigationBarHidden(true)
                    .tabItem {
                        Image(systemName: "mail")
                        Text("Campaigns")
                    }
                    CallListView(
                        viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher())
                    )
                    .environmentObject(app)
                    .navigationBarHidden(true)
                    .tabItem {
                        Image(systemName: "phone")
                        Text("Calls")
                    }
                    MessageListView(
                        viewModel: MessagesViewModel(addressableDataFetcher: AddressableDataFetcher())
                    )
                    .navigationBarHidden(true)
                    .tabItem {
                        Image(systemName: "message")
                        Text("Messages")
                    }
                    ProfileView(viewModel: ProfileViewModel(addressableDataFetcher: AddressableDataFetcher()))
                        .navigationBarHidden(true)
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                }.onAppear {
                    app.verifyPermissions {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                    if let callManager = app.callManager,
                       let knownLead = callManager.getLeadFromLatestCall() {
                        displayIncomingLeadSurvey = knownLead.status == "unknown" && !app.fromAddressableCallView
                    }
                }.sheet(isPresented: $displayIncomingLeadSurvey) {
                    TagIncomingLeadView(
                        viewModel: TagIncomingLeadViewModel(
                            addressableDataFetcher: AddressableDataFetcher()),
                        taggingComplete: { displayIncomingLeadSurvey = false }
                    ).environmentObject(app)
                }
            }
        } else {
            SignInView(
                viewModel: SignInViewModel(addressableDataFetcher: AddressableDataFetcher())
            )
            .environmentObject(app)
            .navigationBarHidden(true)
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView().environmentObject(Application())
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
