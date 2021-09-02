//
//  EditUserAddressView.swift
//  Addressable
//
//  Created by Ari on 9/1/21.
//

import SwiftUI

struct EditUserAddressView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel

    @Binding var isEditingUserAddress: Bool

    init(viewModel: ProfileViewModel, isEditingUserAddress: Binding<Bool>) {
        self.viewModel = viewModel
        self._isEditingUserAddress = isEditingUserAddress
    }
    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 12) {
                    TextField("First Name", text: $viewModel.userFirstName)
                        .textContentType(.givenName)
                        .modifier(TextFieldModifier())

                    TextField("Last Name", text: $viewModel.userLastName)
                        .textContentType(.familyName)
                        .modifier(TextFieldModifier())
                }
                TextField("Company Name (Optional)", text: $viewModel.userBusinessName)
                    .textContentType(.organizationName)
                    .modifier(TextFieldModifier())

                TextField("Address Line 1", text: $viewModel.userAddressLine1)
                    .textContentType(.streetAddressLine1)
                    .modifier(TextFieldModifier())

                TextField("Address Line 2", text: $viewModel.userAddressLine2)
                    .textContentType(.streetAddressLine2)
                    .modifier(TextFieldModifier())
                HStack(spacing: 12) {
                    TextField("City", text: $viewModel.userCity)
                        .textContentType(.addressCity)
                        .modifier(TextFieldModifier())

                    TextField("State", text: $viewModel.userState)
                        .textContentType(.addressState)
                        .modifier(TextFieldModifier())

                    TextField("Zipcode", text: $viewModel.userZipcode)
                        .textContentType(.postalCode)
                        .modifier(TextFieldModifier())

                    TextField("DRE", text: $viewModel.dre)
                        .modifier(TextFieldModifier())
                }
            }
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isEditingUserAddress = false
                    }
                }) {
                    Text("Cancel")
                        .font(Font.custom("Silka-Medium", size: 16))
                        .frame(minWidth: 140, minHeight: 40)
                        .foregroundColor(Color.addressableDarkGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.addressableDarkGray, lineWidth: 1)
                        )
                }
                Spacer()
                Button(action: {
                    // Update User Return Address
                    viewModel.updateUserAddress()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Update")
                        .font(Font.custom("Silka-Medium", size: 16))
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 140, minHeight: 40)
                        .foregroundColor(Color.white)
                        .background(Color.addressablePurple)
                        .cornerRadius(5)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
        }
        .onAppear {
            viewModel.populateFields()
        }
    }
}

struct EditUserAddressView_Previews: PreviewProvider {
    static var previews: some View {
        let isEditingUserAddress = Binding<Bool>(
            get: { false }, set: { _ in }
        )
        EditUserAddressView(
            viewModel: ProfileViewModel(provider: DependencyProvider()),
            isEditingUserAddress: isEditingUserAddress
        )
    }
}
