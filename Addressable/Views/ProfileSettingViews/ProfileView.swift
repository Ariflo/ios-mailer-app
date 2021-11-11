//
//  ProfileView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//
import SwiftUI

enum ProfileSections: String, CaseIterable {
    case handwriting = "Handwriting Style"
    case balance = "Balance"
    case team = "Team"
    case address = "Address Information"
    case api = "API Token"
}

enum ProfileViewAlertTypes {
    case confirmSignOff, appError
}

struct ProfileView: View, Equatable {
    static func == (lhs: ProfileView, rhs: ProfileView) -> Bool {
        lhs.selectedMenuItem == rhs.selectedMenuItem
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: ProfileViewModel

    @State var showingAlert = false
    @State var alertType: ProfileViewAlertTypes = .confirmSignOff
    @State var successfullyLoggedOut: Int?
    @State var displayHandwritingSytles: Bool = false
    @State var isEditingUserAddress: Bool = false

    @Binding var selectedMenuItem: MainMenu

    init(viewModel: ProfileViewModel, selectedMenuItem: Binding<MainMenu>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
    }

    var body: some View {
        let drag = DragGesture()
            .onEnded {
                if $0.translation.height > 0 {
                    withAnimation {
                        withAnimation {
                            displayHandwritingSytles = false
                        }
                    }
                }
            }
        return ZStack {
            // MARK: - Handwriting Sample Styles Image
            displayHandwritingSytles ?
                VStack {
                    Image("StyleSamples")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)
                }
                .gesture(drag)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .background(Color.addressableFadedBlack)
                .transition(.move(edge: .bottom))
                .zIndex(1)
                : nil
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(ProfileSections.allCases, id: \.self) { section in
                    ProfileSettingSectionView(
                        section: section,
                        viewModel: viewModel,
                        displayHandwritingSytles: $displayHandwritingSytles,
                        showingAlert: $showingAlert,
                        alertType: $alertType,
                        isEditingUserAddress: $isEditingUserAddress
                    )
                    .environmentObject(app)
                    .padding(.top, section == .handwriting ? 0 : -10)
                }
                // MARK: - Sign Out Button
                Button(action: {
                    showingAlert = true
                }) {
                    Text("Log Out")
                        .font(Font.custom("Silka-Medium", size: 18))
                        .padding(8)
                        .foregroundColor(Color.white)
                        .background(Color.addressablePurple)
                        .cornerRadius(5)
                        .multilineTextAlignment(.center)
                }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 20))
                Spacer()
            }
            .alert(isPresented: $showingAlert) {
                switch alertType {
                case .confirmSignOff:
                    return Alert(
                        title: .init("Log Out of Addressable?"),
                        primaryButton: .destructive(.init("Log Out")) {
                            viewModel.logout { logoutResponse in
                                guard logoutResponse != nil else {
                                    print("User is unable to succssfully logout")
                                    return
                                }
                                viewModel.analyticsTracker.trackEvent(
                                    .mobileLogoutSuccess,
                                    context: app.persistentContainer.viewContext
                                )
                                logOutOfApplication()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                case .appError:
                    return Alert(title: Text("Sorry something went wrong," +
                                                " try again or reach out to an Addressable " +
                                                " representative if the problem persists."))
                }
            }
            .sheet(isPresented: $isEditingUserAddress) {
                NavigationView {
                    // MARK: - EditUserAddressView
                    EditUserAddressView(
                        viewModel: viewModel,
                        isEditingUserAddress: $isEditingUserAddress
                    )
                    .padding(.horizontal, 20)
                    .navigationBarTitle("Update Address")
                }
            }
        }
    }
    private func logOutOfApplication() {
        // Deregister Device w/ Twilio
        if let delegate = app.callKitProvider {
            delegate.credentialsInvalidated()
        }
        // Unregister device w/ Apple
        UIApplication.shared.unregisterForRemoteNotifications()

        // Reset KeyChain Store
        KeyChainServiceUtil.shared.clearAll()

        // Return to Sign-in
        app.currentView = .signIn
        successfullyLoggedOut = 1
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
