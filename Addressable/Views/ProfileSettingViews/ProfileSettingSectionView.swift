//
//  ProfileSettingSectionView.swift
//  Addressable
//
//  Created by Ari on 8/31/21.
//

import SwiftUI
// swiftlint:disable type_body_length
struct ProfileSettingSectionView: View {
    let section: ProfileSections
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var displayHandwritingSytles: Bool
    @Binding var showingAlert: Bool
    @Binding var alertType: ProfileViewAlertTypes
    @Binding var isEditingUserAddress: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Section Header w/ CTA
            HStack {
                Text(section.rawValue)
                    .font(Font.custom("Silka-Bold", size: 14))
                    .foregroundColor(Color.addressablePurple)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                Spacer()
                Button(action: {
                    getButtonAction(for: section)
                }) {
                    Text(getButtonText(for: section))
                        .font(Font.custom("Silka-Medium", size: 12))
                        .padding(8)
                        .foregroundColor(Color.white)
                        .background(Color.addressablePurple)
                        .cornerRadius(5)
                        .multilineTextAlignment(.center)
                }
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 20))
            }
            .background(Color.addressableLightGray)
            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
            switch section {
            // MARK: - Handwriting Styles Section
            case .handwriting:
                HStack {
                    if viewModel.loadingHandwritings {
                        VStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }.frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: .center
                        )
                    } else {
                        Menu {
                            ForEach(viewModel.handwritings) { handwriting in
                                Button {
                                    viewModel.updateUserHandwritingStyle(to: handwriting.id)
                                } label: {
                                    Text(handwriting.name).font(Font.custom("Silka-Medium", size: 14))
                                }
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Text(getSelectedHandwriting()?.name ?? "No Handwriting Style Selected")
                                    .font(Font.custom("Silka-Medium", size: 14))
                                    .padding()
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .padding()
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.addressableLightestGray, lineWidth: 1)
                                .animation(.easeOut)
                        )
                        .background(Color.white)
                        .frame(minWidth: 295, minHeight: 54)
                        .foregroundColor(.black)
                    }
                }
                .onAppear {
                    viewModel.getAllHandwritings()
                }
                .padding(20)
            // MARK: - Balance Information Section
            case .balance:
                HStack {
                    if viewModel.loadingUserAccount {
                        VStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }.frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: .center
                        )
                    } else {
                        HStack {
                            Text("Radius Tokens:")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            Text("\(viewModel.account?.radiusTokenCount ?? 0)")
                                .font(Font.custom("Silka-Medium", size: 14))
                                .foregroundColor(Color.black)
                        }
                        Spacer()
                        HStack {
                            Text("Card Tokens:")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            Text("\(viewModel.account?.tokenCount ?? 0)")
                                .font(Font.custom("Silka-Medium", size: 14))
                                .foregroundColor(Color.black)
                        }
                        Spacer()
                    }
                }
                .onAppear {
                    viewModel.getUserAccount()
                }
                .padding(20)
            // MARK: - Team Member Section
            case .team:
                VStack(spacing: 0) {
                    if viewModel.loadingUserAccount {
                        VStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }.frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: .center
                        )
                    } else {
                        ScrollView {
                            if let teamMates = viewModel.account?.users {
                                ForEach(teamMates) { teamMate in
                                    HStack(spacing: 6) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            VStack(alignment: .leading) {
                                                Text("Name:")
                                                    .font(Font.custom("Silka-Bold", size: 14))
                                                    .foregroundColor(Color.black)
                                                HStack {
                                                    Text("\(teamMate.firstName)")
                                                        .font(Font.custom("Silka-Medium", size: 14))
                                                        .foregroundColor(Color.black)
                                                    Text("\(teamMate.lastName)")
                                                        .font(Font.custom("Silka-Medium", size: 14))
                                                        .foregroundColor(Color.black)
                                                }
                                            }
                                            VStack(alignment: .leading) {
                                                Text("Email:")
                                                    .font(Font.custom("Silka-Bold", size: 14))
                                                    .foregroundColor(Color.black)
                                                Text("\(teamMate.email)")
                                                    .font(Font.custom("Silka-Medium", size: 14))
                                                    .foregroundColor(Color.black)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 6) {
                                            VStack(alignment: .leading) {
                                                Text("Handwriting:")
                                                    .font(Font.custom("Silka-Bold", size: 14))
                                                    .foregroundColor(Color.black)
                                                Text(getTeammateSelectedHandwriting(with: teamMate.handwritingID))
                                                    .font(Font.custom("Silka-Medium", size: 14))
                                                    .foregroundColor(Color.black)
                                            }
                                            VStack(alignment: .leading) {
                                                Text("Status:")
                                                    .font(Font.custom("Silka-Bold", size: 14))
                                                    .foregroundColor(Color.black)
                                                Text("\(teamMate.status)")
                                                    .font(Font.custom("Silka-Medium", size: 14))
                                                    .foregroundColor(Color.black)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            // MARK: - Address Section
            case .address:
                if viewModel.loadingUserAddress {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }.frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                } else {
                    VStack(alignment: .center, spacing: 12) {
                        VStack(spacing: 8) {
                            Text("Name")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            Text("\(getCurrentUser()?.firstName ?? "Unknown") " +
                                    "\(getCurrentUser()?.lastName ?? "name")")
                                .font(Font.custom("Silka-Medium", size: 14))
                                .foregroundColor(Color.black)
                        }
                        .padding(.vertical, 10)
                        .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                        VStack(spacing: 8) {
                            Text("Company Name")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            Text("\(getCurrentUser()?.companyName ?? "Unknown")")
                                .font(Font.custom("Silka-Medium", size: 14))
                                .foregroundColor(Color.black)
                        }
                        .padding(.bottom, 10)
                        .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                        VStack(spacing: 8) {
                            Text("Address")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(getCurrentUser()?.addressLine1 ?? "Unknown"),")
                                        .font(Font.custom("Silka-Medium", size: 14))
                                        .foregroundColor(Color.black)
                                    Text("\(getCurrentUser()?.addressLine2 ?? "Unknown")")
                                        .font(Font.custom("Silka-Medium", size: 14))
                                        .foregroundColor(Color.black)
                                }
                                Text("\(getCurrentUser()?.city ?? "Unknown"), " +
                                        " \(getCurrentUser()?.state ?? "Unknown") " +
                                        "\(getCurrentUser()?.zipcode ?? "Unknown")")
                                    .font(Font.custom("Silka-Medium", size: 14))
                                    .foregroundColor(Color.black)
                            }.padding(.bottom, 10)
                        }
                    }
                }
            // MARK: - API Detail Section
            case .api:
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 12) {
                        Text("Did you know you can integrate your system with Addressable? You can automatically " +
                                "generate Custom Notes after a meeting, on birthdays, and many other events.")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .foregroundColor(Color.black.opacity(0.3))
                            .multilineTextAlignment(.center)
                        Text("Speak with your Customer Service Representative today to find out more!")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .foregroundColor(Color.black.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your email address:")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            Text("\(getCurrentUser()?.email ?? "Unknown")")
                                .font(Font.custom("Silka-Medium", size: 14))
                                .foregroundColor(Color.black)
                        }
                        HStack {
                            Text("Your API Token:")
                                .font(Font.custom("Silka-Bold", size: 14))
                                .foregroundColor(Color.black)
                            Text("\(getCurrentUser()?.authenticationToken ?? "Unknown")")
                                .font(Font.custom("Silka-Medium", size: 14))
                                .foregroundColor(Color.black)
                        }
                    }
                }.padding(20)
            }
        }
        .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
    }
    private func getTeammateSelectedHandwriting(with handwritingId: Int) -> String {
        return viewModel.handwritings.first { $0.id == handwritingId }?.name ?? "No Handwriting Style Selected"
    }
    private func getSelectedHandwriting() -> Handwriting? {
        if let selectedHandwritingId = getCurrentUser()?.handwritingID {
            return viewModel.handwritings.first { $0.id == selectedHandwritingId }
        }
        return nil
    }
    private func getButtonAction(for section: ProfileSections) {
        switch section {
        case .handwriting:
            withAnimation {
                displayHandwritingSytles = true
            }
        case .balance:
            guard let user = getCurrentUser(),
                  let url = URL(string: "https://live.addressable.app/accounts/\(user.accountID)/token_orders")
            else {
                alertType = .appError
                showingAlert = true
                return
            }
            UIApplication.shared.open(url)
        case .team:
            guard let user = getCurrentUser(),
                  let url = URL(string: "https://live.addressable.app/users/invitation/new?account_id=\(user.accountID)&from_layout=application")
            else {
                alertType = .appError
                showingAlert = true
                return
            }
            UIApplication.shared.open(url)
        case .address:
            withAnimation {
                isEditingUserAddress = true
            }
        case .api:
            guard let url = URL(string: "https://live.addressable.app/api/doc")
            else {
                alertType = .appError
                showingAlert = true
                return
            }
            UIApplication.shared.open(url)
        }
    }
    private func getButtonText(for section: ProfileSections) -> String {
        switch section {
        case .handwriting:
            return "View Handwriting Styles"
        case .balance:
            return "Buy More"
        case .team:
            return "Invite Teammate"
        case .address:
            return "Edit Address"
        case .api:
            return "Learn More"
        }
    }
    private func getCurrentUser() -> User? {
        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let userData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            print("getCurrentUser() from keystore fetch error")
            return nil
        }
        return user
    }
}

#if DEBUG
struct ProfileSettingSectionView_Previews: PreviewProvider {
    static var previews: some View {
        let displayHandwritingSytles = Binding<Bool>(
            get: { false }, set: { _ in }
        )
        let showingAlert = Binding<Bool>(
            get: { false }, set: { _ in }
        )
        let isEditingUserAddress = Binding<Bool>(
            get: { false }, set: { _ in }
        )
        let alertType = Binding<ProfileViewAlertTypes>(
            get: { .appError }, set: { _ in }
        )
        ProfileSettingSectionView(
            section: .address,
            viewModel: ProfileViewModel(provider: DependencyProvider()),
            displayHandwritingSytles: displayHandwritingSytles,
            showingAlert: showingAlert,
            alertType: alertType,
            isEditingUserAddress: isEditingUserAddress
        )
    }
}
#endif
