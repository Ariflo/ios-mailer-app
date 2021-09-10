//
//  ConfirmAndSendMailingView.swift
//  Addressable
//
//  Created by Ari on 7/27/21.
//

import SwiftUI
// swiftlint:disable identifier_name
enum TransactionStatus: String, Codable {
    case ok
    case created
    case paymentRequired = "payment_required"
}

enum ConfirmSendMailingAlertTypes {
    case paymentRequired, error, incompleteMailing
}
// MARK: - ConfirmAndSendMailingView
struct ConfirmAndSendMailingView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ConfirmAndSendMailingViewModel

    @State var showingAlert: Bool = false
    @State var alertType: ConfirmSendMailingAlertTypes = .error

    var isMailingReady: Bool = false

    init(viewModel: ConfirmAndSendMailingViewModel, isMailingReady: Bool) {
        self.viewModel = viewModel
        self.isMailingReady = isMailingReady
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.white.edgesIgnoringSafeArea(.all)
                // MARK: - Mailing Drop Date + Description
                VStack(spacing: 34) {
                    Spacer()
                    Image("ZippyIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    Text("Target Drop Date")
                        .font(Font.custom("Silka-Medium", size: 20))
                    Text("This is the date you would like the mail to start moving to the " +
                            "Post Office. The earliest date is 10 business days from submitting " +
                            "your Mailing.")
                        .font(Font.custom("Silka-Regular", size: 16))
                        .foregroundColor(Color.addressableFadedBlack)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                    HStack(alignment: .bottom, spacing: 8) {
                        HStack {
                            if viewModel.isEditingTargetDropDate {
                                DatePicker(
                                    selection: Binding<Date>(
                                        get: {
                                            getTargetDropDateObject()
                                        }, set: {
                                            viewModel.setSelectedDropDate(selectedDate: $0)
                                        }),
                                    in: getTargetDropDateObject()...,
                                    displayedComponents: .date
                                ) {}
                            } else {
                                Text("\(getFormattedTargetDropDate())")
                                    .font(Font.custom("Silka-Bold", size: 22))
                                    .foregroundColor(Color.black)
                                    .multilineTextAlignment(.leading)
                            }
                            Button(action: {
                                viewModel.isEditingTargetDropDate.toggle()
                            }) {
                                Text(viewModel.isEditingTargetDropDate ? "Set New Drop Date" : "Edit Drop Date")
                                    .font(Font.custom("Silka-Medium", size: 16))
                                    .foregroundColor(Color.addressableFadedBlack)
                                    .underline()
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    Text("We will send " +
                            "\(viewModel.mailing.activeRecipientCount) " +
                            "cards to \(viewModel.mailing.activeRecipientCount) " +
                            "recipients\(getMailingSiteAddress())")
                        .font(Font.custom("Silka-Medium", size: 16))
                        .foregroundColor(Color.addressableFadedBlack)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(Font.custom("Silka-Medium", size: 18))
                                .padding()
                                .foregroundColor(Color.addressableDarkGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.addressableDarkGray, lineWidth: 1)
                                )
                                .multilineTextAlignment(.center)
                        }
                        Button(action: {
                            // Release to Production
                            viewModel.sendMailing { newMailingTransactionReponse in
                                guard newMailingTransactionReponse != nil else {
                                    alertType = .error
                                    showingAlert = true
                                    return
                                }
                                guard newMailingTransactionReponse?.transactionStatus != .paymentRequired
                                else {
                                    alertType = .paymentRequired
                                    showingAlert = true
                                    return
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Release to Production")
                                .font(Font.custom("Silka-Medium", size: 18))
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.addressablePurple)
                                .cornerRadius(5)
                                .multilineTextAlignment(.center)
                        }
                        .disabled(shouldDisableReleaseButton())
                        .opacity(shouldDisableReleaseButton() ? 0.4 : 1)
                    }
                }.padding(20)
            }
            .navigationBarTitle("Release '\(viewModel.mailing.name) \(getTouchNumber())' " +
                                    "to Print", displayMode: .inline)
        }.alert(isPresented: $showingAlert) {
            switch alertType {
            case .paymentRequired:
                return Alert(
                    title: Text("Low Token Balance")
                        .font(Font.custom("Silka-Bold", size: 14)),
                    message: Text("Please purchase more tokens to send this mailing.")
                        .font(Font.custom("Silka-Medium", size: 12)),
                    primaryButton: .default(Text("Buy More")) {
                        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
                              let userData = keyStoreUser.data(using: .utf8),
                              let user = try? JSONDecoder().decode(User.self, from: userData),
                              let scheme = Bundle.main.object(forInfoDictionaryKey: "DOMAIN_SCHEME") as? String,
                              let host = Bundle.main.object(forInfoDictionaryKey: "API_DOMAIN_NAME") as? String,
                              let url = URL(string: "\(scheme)://\(host)/accounts/\(user.accountID)/token_orders")
                        else {
                            alertType = .error
                            showingAlert = true
                            return
                        }
                        UIApplication.shared.open(url)
                    }, secondaryButton: .cancel())
            case .error:
                return Alert(title: Text("Sorry something went wrong, " +
                                            "try again or reach out to an Addressable " +
                                            "representative if the problem persists."))
            case .incompleteMailing:
                return Alert(title: Text("Please complete the mailing setup to send."))
            }
        }
        .onAppear {
            if !isMailingReady {
                self.alertType = .incompleteMailing
                self.showingAlert = true
            }
        }
    }
    private func shouldDisableReleaseButton() -> Bool {
        return viewModel.isEditingTargetDropDate || !isMailingReady
    }
    private func getTouchNumber() -> String {
        return viewModel.mailing.type == MailingType.radius.rawValue ? "| Touch \(isTouchTwoMailing() ? "2" : "1")" : ""
    }
    private func getMailingSiteAddress() -> String {
        if let subjectListEntry = viewModel.mailing.subjectListEntry {
            return "at \(subjectListEntry.siteAddressLine1.trimmingCharacters(in: .whitespacesAndNewlines))" +
                "\(subjectListEntry.siteAddressLine2 ?? "".trimmingCharacters(in: .whitespacesAndNewlines)) " +
                "\(subjectListEntry.siteCity.trimmingCharacters(in: .whitespacesAndNewlines)) " +
                "\(subjectListEntry.siteState.trimmingCharacters(in: .whitespacesAndNewlines)), " +
                "\(subjectListEntry.siteZipcode.trimmingCharacters(in: .whitespacesAndNewlines))."
        } else {
            return "."
        }
    }
    private func getFormattedTargetDropDate() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"

        return dateFormatterPrint.string(from: getTargetDropDateObject())
    }

    private func getTargetDropDateObject() -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatterGet.date(from: viewModel.selectedDropDate) {
            return date
        } else {
            return Date()
        }
    }
    private func isTouchTwoMailing() -> Bool {
        if let relatedTouchMailing = viewModel.mailing.relatedMailing {
            return relatedTouchMailing.parentMailingID == nil
        } else {
            return false
        }
    }
}
