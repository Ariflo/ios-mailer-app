//
//  MailingRecipientsListView.swift
//  Addressable
//
//  Created by Ari on 6/9/21.
//

import SwiftUI

enum AddressType: String, CaseIterable {
    case site, mailing
}

enum RecipientListCategory: String, CaseIterable {
    case mailingList = "Mailing List"
    case removed = "Removed"
    case unavailable = "Unavailable"
    case all = "All"
}
// swiftlint:disable type_body_length
struct MailingRecipientsListView: View, Equatable {
    static func == (lhs: MailingRecipientsListView, rhs: MailingRecipientsListView) -> Bool {
        lhs.viewModel.mailing == rhs.viewModel.mailing &&
            lhs.viewModel.mailing.activeRecipientCount == rhs.viewModel.mailing.activeRecipientCount
    }

    @ObservedObject var viewModel: MailingRecipientsListViewModel

    @State var selectedListCategory: RecipientListCategory = .mailingList
    @State var selectedAddressTypeIndex: Int = 0
    @State var recipientSearchTerm: String = ""
    @State var showingAlert = false
    @State var showingActionSheet = false
    @State var selectedRecipientID: Int?

    @Binding var activeSheetType: MailingDetailSheetTypes?

    init(viewModel: MailingRecipientsListViewModel, activeSheetType: Binding<MailingDetailSheetTypes?>) {
        self.viewModel = viewModel
        self._activeSheetType = activeSheetType
    }
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.mailing.activeRecipientCount < 1 &&
                viewModel.recipients.count < 1 &&
                !viewModel.loadingRecipients {
                VStack {
                    Spacer()
                    Text("No Audience for Mailing")
                        .font(Font.custom("Silka-Medium", size: 22))
                        .padding(.bottom)
                    Button(action: {
                        activeSheetType = .addAudience
                    }) {
                        Text("Select Audience")
                            .font(Font.custom("Silka-Medium", size: 12))
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }.padding()
            } else {
                VStack(spacing: 16) {
                    // MARK: - Site / Mailing Segment Control
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
                        .modifier(TextFieldModifier())
                        .padding(.bottom, 6)
                    // MARK: - List Tabs
                    HStack(spacing: 22) {
                        ForEach(RecipientListCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedListCategory = category
                                }
                            }) {
                                HStack(spacing: 0) {
                                    Text("\(category.rawValue) \(getMailingCount(for: category))")
                                        .font(Font.custom("Silka-Medium", size: 10))
                                        .foregroundColor(Color.black)
                                        .opacity(category == selectedListCategory ? 1 :  0.3)
                                        .textCase(.uppercase)
                                        .padding(.vertical, 8)
                                        .multilineTextAlignment(.center)
                                }
                                .border(
                                    width: category == selectedListCategory ? 2 : 0,
                                    edges: [.bottom],
                                    color: Color.black
                                )
                            }
                            .transition(.move(edge: .bottom))
                        }
                    }
                }
                if viewModel.loadingRecipients {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .onAppear {
                                viewModel.getMailingRecipients()
                            }
                        Spacer()
                    }
                } else {
                    // MARK: - List Of Recipients
                    List {
                        ForEach(viewModel.recipients.filter {
                            isRelatedToSearchQuery($0) && isRelatedToCategory($0)
                        }) { recipient in
                            HStack {
                                Text("\(recipient.fullName)").font(Font.custom("Silka-Bold", size: 13))
                                Spacer()
                                Array(AddressType.allCases)[selectedAddressTypeIndex] == .site ?
                                    Text(recipient.siteAddress).font(Font.custom("Silka-Regular", size: 13))
                                    .multilineTextAlignment(.leading) :
                                    Text(recipient.mailingAddress).font(Font.custom("Silka-Regular", size: 13))
                                    .multilineTextAlignment(.leading)
                                if selectedListCategory != .unavailable && selectedListCategory != .all {
                                    Image(systemName: selectedListCategory == .removed ? "arrow.uturn.left" : "xmark")
                                        .imageScale(.small)
                                        .foregroundColor(selectedListCategory == .removed ? .black : .red)
                                        .onTapGesture {
                                            if isIncompleteRadiusMailing() || selectedListCategory == .removed {
                                                showingAlert = true
                                            } else {
                                                showingActionSheet = true
                                            }
                                            selectedRecipientID = recipient.id
                                        }
                                        .disabled(getMailingStatus() == .mailed)
                                        .opacity(getMailingStatus() == .mailed ? 0.4 : 1)
                                        .alert(isPresented: $showingAlert) {
                                            Alert(
                                                title: Text(selectedListCategory == .removed ?
                                                                "Add Recipient to List?":
                                                                "Remove Recipient from List?")
                                                    .font(Font.custom("Silka-Bold", size: 14)),
                                                message: Text(selectedListCategory == .removed ?
                                                                "Are you sure you want to add recipient to the list?" :
                                                                "Are you sure you want to " +
                                                                "remove recipient from the list?")
                                                    .font(Font.custom("Silka-Medium", size: 12)),
                                                primaryButton: .default(Text("Confirm")) {
                                                    guard selectedRecipientID != nil else { return }
                                                    // swiftlint:disable force_unwrapping
                                                    viewModel.updateListEntry(
                                                        with: selectedRecipientID!,
                                                        with: selectedListCategory == .removed ?
                                                            ListEntryMembershipStatus.member.rawValue :
                                                            ListEntryMembershipStatus.rejected.rawValue
                                                    )
                                                }, secondaryButton: .cancel())
                                        }
                                        .actionSheet(isPresented: $showingActionSheet) {
                                            ActionSheet(
                                                title: Text("Remove Recipient from List?")
                                                    .font(Font.custom("Silka-Bold", size: 14)),
                                                message: Text("Are you sure you want to " +
                                                                "remove recipient from the list?")
                                                    .font(Font.custom("Silka-Medium", size: 12)),
                                                buttons: [
                                                    .default(Text("Remove From this Mailing List")
                                                                .font(Font.custom("Silka-Medium", size: 14))) {
                                                        viewModel.updateListEntry(
                                                            with: selectedRecipientID!,
                                                            with: selectedListCategory == .removed ?
                                                                ListEntryMembershipStatus.member.rawValue :
                                                                ListEntryMembershipStatus.rejected.rawValue
                                                        )
                                                    },
                                                    .destructive(Text("Never Send Mail to this Address")
                                                                    .font(Font.custom("Silka-Medium", size: 14))) {
                                                        // swiftlint:disable force_unwrapping
                                                        viewModel.removeListEntry(
                                                            with: selectedRecipientID!
                                                        )
                                                    },
                                                    .cancel()
                                                ])
                                        }
                                }
                            }
                            .padding(.vertical)
                            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                        }
                        .listRowInsets(.init())
                        .listRowBackground(Color.addressableLightGray)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.addressableLightGray)
                    Spacer()
                }
            }
        }.onAppear {
            viewModel.getMailingRecipients()
        }
    }
    private func isIncompleteRadiusMailing() -> Bool {
        return viewModel.mailing.relatedMailing == nil && viewModel.mailing.type == MailingType.radius.rawValue
    }
    private func getMailingStatus() -> MailingStatus {
        switch viewModel.mailing.mailingStatus {
        case MailingState.mailed.rawValue,
             MailingState.remailed.rawValue:
            return MailingStatus.mailed
        case MailingState.production.rawValue,
             MailingState.printReady.rawValue,
             MailingState.printing.rawValue,
             MailingState.writeReady.rawValue,
             MailingState.writing.rawValue,
             MailingState.mailReady.rawValue,
             MailingState.productionReady.rawValue:
            return MailingStatus.processing
        case MailingState.scheduled.rawValue:
            return MailingStatus.upcoming
        case MailingState.listReady.rawValue,
             MailingState.listAdded.rawValue,
             MailingState.listApproved.rawValue,
             MailingState.draft.rawValue:
            return MailingStatus.draft
        default:
            return MailingStatus.archived
        }
    }
    private func isRelatedToCategory(_ recipient: Recipient) -> Bool {
        let isActive = recipient.listMembership ==
            ListEntryMembershipStatus.member.rawValue && selectedListCategory == .mailingList
        let isRemoved = ((recipient.listMembership ==
                            ListEntryMembershipStatus.rejected.rawValue ||
                            recipient.listMembership ==
                            ListEntryMembershipStatus.removed.rawValue) && selectedListCategory == .removed)
        let isUnavailable = recipient.listMembership ==
            ListEntryMembershipStatus.reserved.rawValue && selectedListCategory == .unavailable

        return isActive || isRemoved || isUnavailable || selectedListCategory == .all
    }
    // swiftlint:disable empty_count
    private func getMailingCount(for category: RecipientListCategory) -> String {
        var count = 0
        switch category {
        case .all:
            count = viewModel.recipients.count
        case .removed:
            count = viewModel.recipients.filter {
                $0.listMembership == ListEntryMembershipStatus.rejected.rawValue ||
                    $0.listMembership == ListEntryMembershipStatus.removed.rawValue
            }.count
        case .unavailable:
            count = viewModel.recipients.filter {
                $0.listMembership == ListEntryMembershipStatus.reserved.rawValue
            }.count
        case .mailingList:
            count = viewModel.recipients.filter {
                $0.listMembership == ListEntryMembershipStatus.member.rawValue
            }.count
        }
        return count > 0 ? "(\(count))" : ""
    }
    private func isRelatedToSearchQuery(_ recipient: Recipient) -> Bool {
        if !recipientSearchTerm.isEmpty {
            return recipient.fullName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .range(of: recipientSearchTerm, options: .caseInsensitive) != nil ||
            (recipient.siteAddress.range(of: recipientSearchTerm, options: .caseInsensitive) != nil &&
                Array(AddressType.allCases)[selectedAddressTypeIndex] == .mailing) ||
            (recipient.mailingAddress.range(of: recipientSearchTerm, options: .caseInsensitive) != nil &&
                Array(AddressType.allCases)[selectedAddressTypeIndex] == .site)
        }
        return true
    }
}

// MARK: - AddressTypeMenuOption
struct AddressTypeMenuOption: View {
    let option: AddressType

    var body: some View {
        // TODO: Figure out a way to pass icons here
        Text(option.rawValue.capitalizingFirstLetter()).font(Font.custom("Silka-Medium", size: 18))
    }
}
