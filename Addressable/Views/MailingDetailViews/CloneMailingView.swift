//
//  CloneMailingView.swift
//  Addressable
//
//  Created by Ari on 8/3/21.
//

import SwiftUI

enum CloneMailingTextFieldOptions: String, CaseIterable {
    case mailingName = "New Mailing Name"
    case targetDropDate = "Ideally, when would you like the first letters to go out?"
    case targetQuantity = "How many handwritten letters would you like to send?"
}

// MARK: - CloneMailingView
struct CloneMailingView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CloneMailingViewModel

    @State var showingAlert: Bool = false

    init(viewModel: CloneMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    Color.white.edgesIgnoringSafeArea(.all)
                    VStack(spacing: 34) {
                        Text("Select the items that you would like to clone.")
                            .font(Font.custom("Silka-Regular", size: 16))
                            .foregroundColor(Color.addressableFadedBlack)
                            .padding(.horizontal, 20)
                            .multilineTextAlignment(.center)
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(CloneMailingTextFieldOptions.allCases, id: \.self) { option in
                                let textFieldBinding = Binding<String>(
                                    get: {
                                        switch option {
                                        case .mailingName:
                                            return viewModel.mailingName
                                        case .targetQuantity:
                                            return viewModel.targetQuantity
                                        default:
                                            return ""
                                        }
                                    },
                                    set: { textFieldValue in
                                        switch option {
                                        case .mailingName:
                                            viewModel.mailingName = textFieldValue
                                        case .targetQuantity:
                                            viewModel.targetQuantity = textFieldValue
                                        default:
                                            break
                                        }
                                    })
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.rawValue).font(Font.custom("Silka-Light", size: 12))
                                    switch option {
                                    case .mailingName,
                                         .targetQuantity:
                                        TextField("", text: textFieldBinding)
                                            .modifier(TextFieldModifier())
                                            .keyboardType(option == .targetQuantity ? .numbersAndPunctuation : .default)
                                    case .targetDropDate:
                                        HStack(alignment: .bottom, spacing: 8) {
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
                                                ) {}.fixedSize().frame(alignment: .leading)
                                            } else {
                                                Text("\(getFormattedTargetDropDate())")
                                                    .font(Font.custom("Silka-Medium", size: 16))
                                                    .foregroundColor(Color.black)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Button(action: {
                                                viewModel.isEditingTargetDropDate.toggle()
                                            }) {
                                                Text(viewModel.isEditingTargetDropDate ?
                                                        "Set New Drop Date" :
                                                        "Edit Drop Date")
                                                    .font(Font.custom("Silka-Medium", size: 12))
                                                    .foregroundColor(Color.addressableFadedBlack)
                                                    .underline()
                                                    .multilineTextAlignment(.center)
                                            }
                                        }.padding(.top)
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 24) {
                            if let layoutTemplate = viewModel.mailing.layoutTemplate {
                                CheckView(
                                    isChecked: viewModel.useLayoutTemplate,
                                    title: "Use Layout Template:",
                                    subTitles: [layoutTemplate.name]
                                ) {
                                    viewModel.useLayoutTemplate.toggle()
                                }
                                .multilineTextAlignment(.center)
                            }
                            if let messageTemplateName = viewModel.mailing.customNoteTemplateName {
                                CheckView(
                                    isChecked: viewModel.useMessageTemplate,
                                    title: "Use Message Template:",
                                    subTitles: [messageTemplateName]
                                ) {
                                    viewModel.useMessageTemplate.toggle()
                                }
                                .multilineTextAlignment(.center)
                            }
                            viewModel.mailing.listUploadIdToNameMap.isEmpty ? nil :
                                CheckView(
                                    isChecked: viewModel.useAudienceList,
                                    title: "Use List(s):",
                                    subTitles: viewModel.mailing.listUploadIdToNameMap
                                        .reduce([]) { audienceNames, audienceMap in
                                            audienceNames + audienceMap.values
                                        }
                                ) {
                                    viewModel.useAudienceList.toggle()
                                }
                                .multilineTextAlignment(.center)
                        }
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
                                viewModel.cloneMailing { clonedMailing in
                                    guard clonedMailing != nil else {
                                        showingAlert = true
                                        return
                                    }
                                    // swiftlint:disable force_unwrapping
                                    viewModel.mailing = clonedMailing!
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                Text("Clone Mailing")
                                    .font(Font.custom("Silka-Medium", size: 18))
                                    .padding()
                                    .foregroundColor(Color.white)
                                    .background(Color.addressablePurple)
                                    .cornerRadius(5)
                                    .multilineTextAlignment(.center)
                            }
                            .disabled(shouldDisableCloneButton())
                            .opacity(shouldDisableCloneButton() ? 0.4 : 1)
                        }
                    }.padding(20)
                }
            }
            .navigationBarTitle("Clone '\(viewModel.mailing.name) \(getTouchNumber())'", displayMode: .inline)
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text("Sorry something went wrong, " +
                                "try again or reach out to an Addressable " +
                                "representative if the problem persists."))
        }
    }
    private func shouldDisableCloneButton() -> Bool {
        if let quantity = Int(viewModel.targetQuantity) {
            return viewModel.mailingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                viewModel.targetQuantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                quantity < 1 ||
                viewModel.isEditingTargetDropDate
        }
        return true
    }
    private func getFormattedTargetDropDate() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"

        return dateFormatterPrint.string(from: getTargetDropDateObject())
    }

    private func getTargetDropDateObject() -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatterGet.date(from: viewModel.targetDropDate) {
            return date
        } else {
            return Date()
        }
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
    private func isTouchTwoMailing() -> Bool {
        if let relatedTouchMailing = viewModel.mailing.relatedMailing {
            return relatedTouchMailing.parentMailingID == nil
        } else {
            return false
        }
    }
}
