//
//  ProfileView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//
import SwiftUI

struct ProfileView: View, Equatable {
    static func == (lhs: ProfileView, rhs: ProfileView) -> Bool {
        lhs.selectedMenuItem == rhs.selectedMenuItem
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: ProfileViewModel

    @State var showingAlert = false
    @State var successfullyLoggedOut: Int?

    @Binding var selectedMenuItem: MainMenu

    init(viewModel: ProfileViewModel, selectedMenuItem: Binding<MainMenu>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
    }

    var body: some View {
        NavigationLink(destination: AppView().environmentObject(app), tag: 1, selection: $successfullyLoggedOut) {
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
                                KeyChainServiceUtil.shared[userAppToken] = nil
                                KeyChainServiceUtil.shared[userMobileClientIdentity] = nil
                                logOutOfApplication()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }.frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }
    private func logOutOfApplication() {
        if KeyChainServiceUtil.shared[userBasicAuthToken] == nil &&
            KeyChainServiceUtil.shared[userMobileClientIdentity] == nil &&
            KeyChainServiceUtil.shared[userAppToken] == nil {
            app.currentView = .signIn
            successfullyLoggedOut = 1
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedMenuItem = Binding<MainMenu>(
            get: { MainMenu.campaigns }, set: { _ in }
        )
        ProfileView(viewModel: ProfileViewModel(provider: DependencyProvider()), selectedMenuItem: selectedMenuItem)
    }
}
#endif
