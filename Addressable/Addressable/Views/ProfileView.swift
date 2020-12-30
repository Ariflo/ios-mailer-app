//
//  SettingsView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct ProfileView: View {
    @State var showingAlert = false
    @State var successfullyLoggedOut: Int?

    var body: some View {
        NavigationLink(destination: AppView(), tag: 1, selection: $successfullyLoggedOut) {
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
                        KeyChainServiceUtil.shared[USER_BASIC_AUTH_TOKEN] = nil
                        successfullyLoggedOut = 1
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
