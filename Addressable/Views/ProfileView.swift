//
//  ProfileView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    @State var showingAlert = false
    @State var successfullyLoggedOut: Int?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationLink(destination: AppView(), tag: 1, selection: $successfullyLoggedOut) {
            VStack {
                Button(action: {
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.to.line")
                        Text("Sign Out")
                    }
                    .font(.title2)
                }.alert(isPresented: $showingAlert) {
                    .init(
                        title: .init("Sign Out of Addressable?"),
                        primaryButton: .destructive(.init("Sign Out")) {
                            viewModel.logout { logoutResponse in
                                guard logoutResponse != nil else {
                                    print("User is unable to succssfully logout")
                                    return
                                }
                                KeyChainServiceUtil.shared[userBasicAuthToken] = nil
                                KeyChainServiceUtil.shared[userMobileClientIdentity] = nil
                                successfullyLoggedOut = 1
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                if let versionNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
                   let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("v\(appVersion) (\(versionNumber))")
                        .foregroundColor(Color.black)
                        .padding()
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
