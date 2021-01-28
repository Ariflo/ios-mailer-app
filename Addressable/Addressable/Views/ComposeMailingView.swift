//
//  ComposeMailingView.swift
//  Addressable
//
//  Created by Ari on 1/25/21.
//

import SwiftUI
// MARK: - ComposeMailingSteps
enum ComposeMailingSteps: String, CaseIterable {
    case toForm = "Send Note To"
    case selectCard = "Select Card"
    case selectTemplate = "Select Message Template"
    case writeMessage = "Write Message"
    case fromForm = "Return Address"
    case confirmation = "Thank You!"
}
// MARK: - ComposeMailingAlerts
enum ComposeMailingAlerts {
    case requiredFieldsEmpty, confirmMailing
}

// MARK: - ComposeMailingView
struct ComposeMailingView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var viewModel: ComposeMailingViewModel

    @State var showingAlert: Bool = false
    @State private var alertType: ComposeMailingAlerts = .requiredFieldsEmpty


    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.step {
                case .toForm:
                    ComposeMailingToFormView(viewModel: viewModel)
                case .selectCard:
                    ComposeMailingCoverArtSelectionView(viewModel: viewModel)
                case .selectTemplate:
                    ComposeMailingTemplateSelectionView(viewModel: viewModel)
                case .writeMessage:
                    ComposeMailingBodyView(viewModel: viewModel)
                case .fromForm:
                    ComposeMailingFromFormView(viewModel: viewModel)
                case .confirmation:
                    ComposeMailingConfirmationView(viewModel: viewModel)
                }
            }
            .alert(isPresented: $showingAlert) {
                switch alertType {
                case .requiredFieldsEmpty:
                    return Alert(title: Text("Please Fill In All Required Fields"))
                case .confirmMailing:
                    return Alert(
                        title: Text("Send Mailing?"), message: Text("You are about to send a personalized note in the mail"),
                        primaryButton: .default(Text("Confirm")) {
                            viewModel.updateCustomNote()
                            viewModel.sendMailing()
                            viewModel.step.next()
                        }, secondaryButton: .cancel())
                }
            }
            .toolbar {
                // MARK: - Wizard Back Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            guard viewModel.step == .toForm else {
                                viewModel.step.back()
                                return
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    ) {
                        if viewModel.step != .confirmation {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
                // MARK: - Wizard Next / Finish Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            guard !getRequiredFieldsIsEmpty(for: viewModel.step) else {
                                alertType = .requiredFieldsEmpty
                                showingAlert = true
                                return
                            }

                            guard viewModel.step != .fromForm else {
                                alertType = .confirmMailing
                                showingAlert = true
                                return
                            }


                            guard viewModel.step == .confirmation else {
                                viewModel.updateCustomNote()
                                viewModel.step.next()
                                return
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    ) {
                        HStack(spacing: 6) {
                            viewModel.step != .confirmation ? Text(viewModel.step == .fromForm ? "Send" : "Next")
                                : Text("Campaigns")
                            viewModel.step != .fromForm && viewModel.step != .confirmation  ? Image(systemName: "chevron.right") : nil
                        }
                    }
                }
            }
            .navigationBarTitle(Text(viewModel.step.rawValue), displayMode: .inline)
        }
    }

    func getRequiredFieldsIsEmpty(for step: ComposeMailingSteps) -> Bool {
        let ws = CharacterSet.whitespacesAndNewlines

        let toFirstName = viewModel.toFirstName.trimmingCharacters(in: ws)
        let toLastName = viewModel.toLastName.trimmingCharacters(in: ws)
        let toAddressline1 = viewModel.toAddressLine1.trimmingCharacters(in: ws)
        let toCity = viewModel.toCity.trimmingCharacters(in: ws)
        let toState = viewModel.toState.trimmingCharacters(in: ws)
        let toZipcode = viewModel.toZipcode.trimmingCharacters(in: ws)

        let fromFirstName = viewModel.fromFirstName.trimmingCharacters(in: ws)
        let fromLastName = viewModel.fromLastName.trimmingCharacters(in: ws)
        let fromAddressline1 = viewModel.fromAddressLine1.trimmingCharacters(in: ws)
        let fromCity = viewModel.fromCity.trimmingCharacters(in: ws)
        let fromState = viewModel.fromState.trimmingCharacters(in: ws)
        let fromZipcode = viewModel.fromZipcode.trimmingCharacters(in: ws)

        if step == ComposeMailingSteps.toForm {
            return toFirstName.isEmpty ||
                toLastName.isEmpty ||
                toAddressline1.isEmpty ||
                toCity.isEmpty ||
                toState.isEmpty ||
                toZipcode.isEmpty
        } else if step == ComposeMailingSteps.fromForm {
            return fromFirstName.isEmpty ||
                fromLastName.isEmpty ||
                fromAddressline1.isEmpty ||
                fromCity.isEmpty ||
                fromState.isEmpty ||
                fromZipcode.isEmpty
        }

        return false
    }
}

// MARK: - ComposeMailingToFormView
struct ComposeMailingToFormView: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            TextField("First Name", text: $viewModel.toFirstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.givenName)
                .disableAutocorrection(true)

            TextField("Last Name", text: $viewModel.toLastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.familyName)
                .disableAutocorrection(true)

            TextField("Business Name (Optional)", text: $viewModel.toBusinessName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.organizationName)
                .disableAutocorrection(true)

            TextField("Address Line 1", text: $viewModel.toAddressLine1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.streetAddressLine1)
                .disableAutocorrection(true)

            TextField("Address Line 2", text: $viewModel.toAddressLine2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.streetAddressLine2)
                .disableAutocorrection(true)

            TextField("City", text: $viewModel.toCity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.addressCity)
                .disableAutocorrection(true)

            TextField("State", text: $viewModel.toState)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.addressState)
                .disableAutocorrection(true)

            TextField("Zipcode", text: $viewModel.toZipcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.postalCode)
                .disableAutocorrection(true)
        }
    }
}
// MARK: - ComposeMailingFromFormView
struct ComposeMailingFromFormView: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            TextField("First Name", text: $viewModel.fromFirstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.givenName)
                .disableAutocorrection(true)

            TextField("Last Name", text: $viewModel.fromLastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.familyName)
                .disableAutocorrection(true)

            TextField("Business Name (Optional)", text: $viewModel.fromBusinessName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.organizationName)
                .disableAutocorrection(true)

            TextField("Address Line 1", text: $viewModel.fromAddressLine1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.streetAddressLine1)
                .disableAutocorrection(true)

            TextField("Address Line 2", text: $viewModel.fromAddressLine2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.streetAddressLine2)
                .disableAutocorrection(true)

            TextField("City", text: $viewModel.fromCity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.addressCity)
                .disableAutocorrection(true)

            TextField("State", text: $viewModel.fromState)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.addressState)
                .disableAutocorrection(true)

            TextField("Zipcode", text: $viewModel.fromZipcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.postalCode)
                .disableAutocorrection(true)
        }.onAppear {
            viewModel.getMailingReturnAddress()
        }
    }
}
// MARK: - ComposeMailingCoverArtSelectionView
struct ComposeMailingCoverArtSelectionView: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List(viewModel.mailingArt.filter { $0.imageUrl != nil && $0.id != nil }) { coverArt in
            MailingCoverArtRow(viewModel: viewModel, coverImage: coverArt)
        }.onAppear {
            viewModel.getMailingCoverArtOptions()
        }.listStyle(PlainListStyle())
    }
}
// MARK: - MailingCoverArtRow
private struct MailingCoverArtRow: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    var coverImage: MailingCoverArt
    var coverImageName: String


    init(viewModel: ComposeMailingViewModel, coverImage: MailingCoverArt) {
        self.viewModel = viewModel
        self.coverImage = coverImage
        self.coverImageName = coverImage.name?.replacingOccurrences(of: "_", with: " ") ?? "Unkown"
    }

    var body: some View {
        Button(action: {
            viewModel.selectedCoverArtID = coverImage.id
        }) {
            HStack(spacing: 6) {
                CustomNote.CoverImage(
                    withURL: coverImage.imageUrl!,
                    size: 80,
                    cornerRadius: 12
                )
                Text(coverImageName)

                Spacer()

                viewModel.selectedCoverArtID == coverImage.id  ? Image(systemName: "checkmark").foregroundColor(Color.blue) : nil
            }
            .padding(.vertical, 8)
        }
    }
}
// MARK: - ComposeMailingTemplateSelectionView
struct ComposeMailingTemplateSelectionView: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if viewModel.messageTemplates.count > 0 {
                ForEach(viewModel.messageTemplates) { template in
                    MessageTemplateRow(viewModel: viewModel, messageTemplate: template)
                }
            } else {
                Button(action: {
                    // Navigate to ComposeMailingBodyView
                    viewModel.step.next()
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Message Templates Avaliable").font(.title2)
                        Text("Create new message").font(.subheadline)
                    }.padding(.vertical, 8)
                }
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            viewModel.getMessageTemplates()
        }
    }
}
// MARK: - MessageTemplateRow
private struct MessageTemplateRow: View {
    @ObservedObject var viewModel: ComposeMailingViewModel
    @State private var showingAlert: Bool = false

    var messageTemplate: MessageTemplate


    init(viewModel: ComposeMailingViewModel, messageTemplate: MessageTemplate) {
        self.viewModel = viewModel
        self.messageTemplate = messageTemplate
    }

    var body: some View {
        Button(action: {
            showingAlert = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Text(messageTemplate.title).font(.title2)
                Text(messageTemplate.body)
                    .font(.body)
                    .foregroundColor(Color.gray)
            }.padding(.vertical, 8)
        }.alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Use '\(messageTemplate.title)'?"),
                primaryButton: .default(Text("Use Template")) {
                    viewModel.selectedMessageTemplateID = messageTemplate.id
                    viewModel.body = messageTemplate.body
                    viewModel.step.next()
                }, secondaryButton: .cancel())
        }
    }
}
// MARK: - ComposeMailingBodyView
struct ComposeMailingBodyView: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        TextEditor(text: $viewModel.body).padding()
    }
}

// MARK: - ComposeMailingConfirmationView
struct ComposeMailingConfirmationView: View {
    @ObservedObject var viewModel: ComposeMailingViewModel

    init(viewModel: ComposeMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image("ZippyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            Text("Your note is being prepared and will mail in the next 1-2 days.")
                .padding(25)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - ComposeMailingView_Previews
struct ComposeMailingView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMailingView(viewModel: ComposeMailingViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
