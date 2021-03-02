//
//  AppView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct AppView: View {
    @EnvironmentObject var app: Application

    var body: some View {
        /// User Authenticaton Check
        if KeyChainServiceUtil.shared[userBasicAuthToken] != nil {
            if app.displayCallView {
                AddressableCallView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher())).navigationBarHidden(true)
            } else {
                TabView {
                    MailingsView(
                        viewModel: MailingsViewModel(addressableDataFetcher: AddressableDataFetcher())
                    )
                    .navigationBarHidden(true)
                    .tabItem {
                        Image(systemName: "mail")
                        Text("Campaigns")
                    }
                    CallListView(
                        viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher())
                    )
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
                    ProfileView()
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
                }
            }
        } else {
            SignInView(
                viewModel: SignInViewModel(addressableDataFetcher: AddressableDataFetcher())
            ).navigationBarHidden(true)
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView().environmentObject(Application())
    }
}
