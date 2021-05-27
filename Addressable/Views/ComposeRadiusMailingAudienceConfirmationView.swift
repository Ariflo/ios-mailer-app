//
//  ComposeRadiusMailingAudienceConfirmationView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

enum AddressType: String, CaseIterable {
    case site, mailing
}

enum RecipientListCategory: String, CaseIterable {
    case mailingList = "Mailing List"
    case removed = "Removed"
    case unavailable = "Unavailable"
}

struct ComposeRadiusMailingAudienceConfirmationView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State var showingAlert = false
    @State var selectedRecipientID: Int?
    @State var selectedAddressTypeIndex: Int = 0
    @State var recipientSearchTerm: String = ""
    @State var selectedListCategory: RecipientListCategory = .mailingList

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel

        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UITableView.appearance().showsVerticalScrollIndicator = false
        UITextField.appearance().clearButtonMode = .whileEditing
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            // MARK: - Count Pill
            HStack {
                HStack {
                    Image(systemName: "person.3")
                    Text("\(viewModel.touchOneMailing?.activeRecipientCount ?? 0)")
                        .font(Font.custom("Silka-Medium", size: 18))
                }
                .padding(.horizontal, 19)
                .padding(.vertical, 6)
            }
            .background(Color.addressableDarkerGray)
            .cornerRadius(50.0)
            .frame(minWidth: 98, minHeight: 34)
            // MARK: - Instructions
            Text("Feel free to remove any that you feel aren't suitable. " +
                    "They will be replaced with alternatives to ensure you get the same reach")
                .font(Font.custom("Silka-Regular", size: 12))
                .padding()
                .foregroundColor(Color.addressableFadedBlack)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
            // MARK: - Instructions
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text("Address:").font(Font.custom("Silka-Light", size: 12))
                    Spacer()
                    Picker(selection: $selectedAddressTypeIndex, label: Text("Address")) {
                        ForEach(Array(AddressType.allCases).indices) { optionIndex in
                            AddressTypeMenuOption(option: AddressType.allCases[optionIndex]).tag(optionIndex)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                // MARK: - Search Input
                TextField("Search", text: $recipientSearchTerm)
                    .font(Font.custom("Silka-Medium", size: 12))
                    .padding(.leading, 12)
                    .frame(minWidth: 295, minHeight: 34)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.addressableLightestGray, lineWidth: 1)
                    )
                // MARK: - List Tabs
                HStack {
                    let countRemoved = viewModel.touchOneMailing!.recipients.filter { $0.status == ListEntryStatus.rejected.rawValue }.count
                    ForEach(RecipientListCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedListCategory = category
                        }) {
                            HStack {
                                category == .removed ? Spacer() : nil
                                HStack(spacing: 4) {
                                    Text(category.rawValue)
                                        .font(Font.custom("Silka-Medium", size: 12))
                                        .foregroundColor(Color.black)
                                        .opacity(category == selectedListCategory ? 1 :  0.3)
                                        .textCase(.uppercase)
                                        .padding(.bottom, 8)
                                    category == .removed && countRemoved > 0 ?
                                        Text("(\(countRemoved))")
                                        .font(Font.custom("Silka-Medium", size: 12))
                                        .foregroundColor(Color.black)
                                        .padding(.bottom, 8)
                                        .opacity(category == selectedListCategory ? 1 :  0.3) : nil
                                }.border(
                                    width: category == selectedListCategory ? 2 : 0,
                                    edges: [.bottom], color: Color.black
                                )
                                category == .removed ? Spacer() : nil
                            }
                        }
                    }
                }
            }
            // MARK: - List Of Recipients
            List {
                ForEach(viewModel.touchOneMailing!.recipients.filter {
                    isRelatedToSearchQuery($0) && (
                        ($0.status == ListEntryStatus.active.rawValue && selectedListCategory == .mailingList) ||
                            ($0.status == ListEntryStatus.rejected.rawValue && selectedListCategory == .removed) ||
                            ($0.status == ListEntryStatus.unavailable.rawValue && selectedListCategory == .unavailable)
                    )
                }) { recipient in
                    HStack(spacing: 6) {
                        Text("\(recipient.fullName)").font(Font.custom("Silka-Bold", size: 12))
                        Spacer()
                        Array(AddressType.allCases)[selectedAddressTypeIndex] == .site ?
                            Text(recipient.siteAddress).font(Font.custom("Silka-Regular", size: 12)).multilineTextAlignment(.leading) :
                            Text(recipient.mailingAddress).font(Font.custom("Silka-Regular", size: 12)).multilineTextAlignment(.leading)
                        Spacer()
                        Button(action: {
                            showingAlert = true
                            selectedRecipientID = recipient.id
                        }) {
                            Image(systemName: selectedListCategory == .removed ? "arrow.uturn.left" : "xmark")
                                .resizable()
                                .frame(maxWidth: 8, maxHeight: 8)
                                .foregroundColor(selectedListCategory == .removed ? .black : .red)
                        }
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text(selectedListCategory == .removed ? "Add Recipient to List?": "Remove Recipient from List?"),
                            message: Text(selectedListCategory == .removed ?  "Are you sure you want to add recipient to the list?" : "Are you sure you want to remove recipient from the list?"),
                            primaryButton: .default(Text("Confirm")) {
                                guard selectedRecipientID != nil else { return }
                                viewModel.updateListEntry(
                                    for: selectedRecipientID!,
                                    with: selectedListCategory == .removed ? ListEntryStatus.active.rawValue : ListEntryStatus.rejected.rawValue)
                            }, secondaryButton: .cancel())
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                .listRowBackground(Color.addressableLightGray)
            }
            .listStyle(PlainListStyle())
            .background(Color.addressableLightGray)
        }
        .padding(.horizontal, 40)
    }

    private func isRelatedToSearchQuery(_ recipient: Recipient) -> Bool {
        if !recipientSearchTerm.isEmpty {
            return recipient.fullName.trimmingCharacters(in: .whitespacesAndNewlines).range(of: recipientSearchTerm, options: .caseInsensitive) != nil ||
                (recipient.siteAddress.range(of: recipientSearchTerm, options: .caseInsensitive) != nil &&
                    Array(AddressType.allCases)[selectedAddressTypeIndex] == .mailing) ||
                (recipient.mailingAddress.range(of: recipientSearchTerm, options: .caseInsensitive) != nil &&
                    Array(AddressType.allCases)[selectedAddressTypeIndex] == .site)
        }
        return true
    }
}

struct ComposeRadiusMailingAudienceConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingAudienceConfirmationView(viewModel: ComposeRadiusMailingViewModel(selectedRadiusMailing: nil))
    }
}

struct AddressTypeMenuOption: View {
    let option: AddressType

    var body: some View {
        // TODO: Figure out a way to pass icons here
        Text(option.rawValue.capitalizingFirstLetter()).font(Font.custom("Silka-Medium", size: 18))
    }
}
