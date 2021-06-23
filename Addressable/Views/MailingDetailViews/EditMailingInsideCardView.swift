//
//  EditMailingInsideCardView.swift
//  Addressable
//
//  Created by Ari on 6/16/21.
//

import SwiftUI

struct EditMailingInsideCardView: View, Equatable {
    static func == (lhs: EditMailingInsideCardView, rhs: EditMailingInsideCardView) -> Bool {
        lhs.viewModel.messageTemplateId == rhs.viewModel.messageTemplateId
    }

    @ObservedObject var viewModel: EditMailingInsideCardViewModel
    @Binding var isEditingMailing: Bool
    @Binding var isShowingInsideCardEditAlert: Bool

    init(
        viewModel: EditMailingInsideCardViewModel,
        isEditingMailing: Binding<Bool>,
        isShowingInsideCardEditAlert: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._isEditingMailing = isEditingMailing
        self._isShowingInsideCardEditAlert = isShowingInsideCardEditAlert
    }

    var body: some View {
        VStack(spacing: 6) {
            if viewModel.loadingMessageTemplate {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else {
                TextEditor(text: $viewModel.messageTemplateBody)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                // MARK: - Confirm Edit Buttons
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isShowingInsideCardEditAlert = true
                        }
                    }) {
                        Text("Cancel")
                            .font(Font.custom("Silka-Medium", size: 16))
                            .frame(minWidth: 145, minHeight: 40)
                            .foregroundColor(Color.addressableDarkGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.addressableDarkGray, lineWidth: 1)
                            )
                    }
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            viewModel.updateMailingMessageTemplate { updatedTemplate in
                                guard updatedTemplate != nil else { return }
                                isEditingMailing = false
                            }
                        }
                    }) {
                        Text("Update Template")
                            .font(Font.custom("Silka-Medium", size: 16))
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 145, minHeight: 40)
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                    }
                }.padding()
            }
        }.onAppear {
            viewModel.getMessageTemplate()
        }
    }
}
