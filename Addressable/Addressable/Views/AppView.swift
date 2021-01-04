//
//  MainView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct AppView: View {
    var body: some View {
        /// User Authenticaton Check
        if KeyChainServiceUtil.shared[USER_BASIC_AUTH_TOKEN] != nil {
            TabView {
                MailingsView(
                    viewModel: MailingsViewModel(addressableDataFetcher: AddressableDataFetcher())
                )
                .navigationBarHidden(true)
                .tabItem {
                    Image(systemName: "mail")
                    Text("Mailings")
                }
                CallsView()
                    .navigationBarHidden(true)
                    .tabItem {
                        Image(systemName: "phone")
                        Text("Calls")
                    }
                MessagesView()
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
        AppView()
    }
}
