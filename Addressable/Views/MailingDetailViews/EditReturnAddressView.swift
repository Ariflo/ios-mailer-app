//
//  EditReturnAddressView.swift
//  Addressable
//
//  Created by Ari on 6/15/21.
//

import SwiftUI

struct EditReturnAddressView: View {
    @ObservedObject var viewModel: EditReturnAddressViewModel

    @Binding var isEditingReturnAddress: Bool
    var toggleAlert: () -> Void
    var sendReturnAddressUpdatedAnalyticEvent: () -> Void

    init(
        viewModel: EditReturnAddressViewModel,
        isEditingReturnAddress: Binding<Bool>,
        toggleAlert: @escaping () -> Void,
        sendReturnAddressUpdatedAnalyticEvent: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self._isEditingReturnAddress = isEditingReturnAddress
        self.toggleAlert = toggleAlert
        self.sendReturnAddressUpdatedAnalyticEvent = sendReturnAddressUpdatedAnalyticEvent
    }
    var body: some View {
        VStack {
            Text("Update Return Address").font(Font.custom("Silka-Bold", size: 16))
            VStack {
                HStack(spacing: 12) {
                    TextField("First Name", text: $viewModel.fromFirstName)
                        .textContentType(.givenName)
                        .modifier(TextFieldModifier())

                    TextField("Last Name", text: $viewModel.fromLastName)
                        .textContentType(.familyName)
                        .modifier(TextFieldModifier())
                }
                TextField("Business Name (Optional)", text: $viewModel.fromBusinessName)
                    .textContentType(.organizationName)
                    .modifier(TextFieldModifier())

                TextField("Address Line 1", text: $viewModel.fromAddressLine1)
                    .textContentType(.streetAddressLine1)
                    .modifier(TextFieldModifier())

                TextField("Address Line 2", text: $viewModel.fromAddressLine2)
                    .textContentType(.streetAddressLine2)
                    .modifier(TextFieldModifier())
                HStack(spacing: 12) {
                    TextField("City", text: $viewModel.fromCity)
                        .textContentType(.addressCity)
                        .modifier(TextFieldModifier())

                    TextField("State", text: $viewModel.fromState)
                        .textContentType(.addressState)
                        .modifier(TextFieldModifier())

                    TextField("Zipcode", text: $viewModel.fromZipcode)
                        .textContentType(.postalCode)
                        .modifier(TextFieldModifier())
                }
            }
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isEditingReturnAddress = false
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
                    viewModel.updateMailingReturnAddress { updatedMailing in
                        if let updatedMailing = updatedMailing {
                            viewModel.mailing = updatedMailing
                            withAnimation(.easeOut(duration: 0.5)) {
                                isEditingReturnAddress = false
                                toggleAlert()
                            }
                            sendReturnAddressUpdatedAnalyticEvent()
                        }
                    }
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
            .onAppear {
                viewModel.populateFields()
            }
        }
    }
}
