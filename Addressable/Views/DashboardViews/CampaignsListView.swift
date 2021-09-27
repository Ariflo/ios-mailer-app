//
//  CampaignsListView.swift
//  Addressable
//
//  Created by Ari on 6/1/21.
//

import SwiftUI

enum MailingStatus: String, CaseIterable {
    case mailed = "Mailed"
    case processing = "In Process"
    case upcoming = "Upcoming"
    case draft = "Draft"
    case archived = "Archived"
    case canceled = "Canceled"
}
enum MailingState: String, CaseIterable {
    case draft
    case scheduled
    case pending = "pending_payment"
    case listReady = "list_ready"
    case listAdded = "list_added"
    case listApproved = "list_approved"
    case productionReady = "production_ready"
    case production
    case printReady = "print_ready"
    case printing
    case writeReady = "write_ready"
    case writing
    case mailReady = "mail_ready"
    case remailed
    case mailed
    case delivered
    case canceled
    case deleted
    case archived
}

struct CampaignsListView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CampaignsViewModel

    @Binding var selectedMenuItem: MainMenu

    @State var mailingSearchTerm: String = ""
    @State var selectedFilters: [String] = []
    @State var displayFilterMenu: Bool = false

    let maxMailingsDisplayCount: Int = 3

    init(viewModel: CampaignsViewModel, selectedMenuItem: Binding<MainMenu>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
    }

    var body: some View {
        VStack {
            // MARK: - Filter Header Row
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            displayFilterMenu.toggle()
                        }
                    }) {
                        CustomHeader(
                            name: "Filters",
                            image: Image(systemName: "slider.horizontal.3"),
                            backgroundColor: Color.addressableLightGray
                        ).padding(.vertical)
                    }
                    if !selectedFilters.isEmpty || !mailingSearchTerm.isEmpty {
                        Button(action: {
                            selectedFilters = []
                            mailingSearchTerm = ""
                        }) {
                            HStack(spacing: 4) {
                                Text("Clear All").font(Font.custom("Silka-Medium", size: 12))
                                Image(systemName: "xmark")
                                    .imageScale(.small)
                                    .padding(.leading, 4)
                            }
                            .foregroundColor(Color.addressableFadedBlack)
                            .opacity(0.3)
                        }
                    }
                }
                if !selectedFilters.isEmpty {
                    CampaignsFilterBoxesView(
                        filterCases: selectedFilters,
                        selectedFilters: $selectedFilters
                    ).frame(maxHeight: 65)
                }
            }
            .padding(.horizontal, 20)
            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
            // MARK: - Filter Menu
            VStack(alignment: .leading, spacing: 20) {
                displayFilterMenu || !mailingSearchTerm.isEmpty ?
                    TextField("Search", text: $mailingSearchTerm)
                    .modifier(TextFieldModifier()) : nil
                displayFilterMenu ?
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Status")
                            .font(Font.custom("Silka-Medium", size: 12))
                        CampaignsFilterBoxesView(
                            filterCases: MailingStatus.allCases.map { $0.rawValue },
                            selectedFilters: $selectedFilters
                        )
                        .frame(maxHeight: 51)
                    }.padding(.bottom, 12) : nil
            }
            .padding(.horizontal, 20)
            .transition(.move(edge: .bottom))
            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
            // MARK: - Campaigns Mailing List
            RefreshableScrollView(refreshing: $viewModel.refreshMailingData) {
                let isListFiltered = !(selectedFilters.isEmpty && mailingSearchTerm.isEmpty)

                if viewModel.mailings.filter { mailing in isRelatedToSearchQuery(mailing) }.isEmpty &&
                    !viewModel.mailings.isEmpty {
                    HStack {
                        Spacer()
                        Text("No mailings match '\(mailingSearchTerm)' search term")
                            .font(Font.custom("Silka-Regular", size: 16))
                            .padding()
                        Spacer()
                    }.background(Color.addressableLightGray)
                } else {
                    ForEach(MailingStatus.allCases, id: \.self) { status in
                        isListFiltered || getMailings(with: status).isEmpty ? nil :
                            CampaignSectionHeaderView(
                                status: status,
                                count: getMailings(with: status).count,
                                selectedFilters: $selectedFilters
                            )
                        if let mailingStatus = selectedFilters.isEmpty ? status :
                            getMailingStatusFromFilters(with: status) {
                            if !getMailings(with: mailingStatus).isEmpty {
                                let mailingList = getMailings(
                                    with: mailingStatus).filter { isRelatedToSearchQuery($0)
                                }
                                ForEach(mailingList.indices) { mailingIndex in
                                    if mailingIndex < (isListFiltered ? mailingList.count :
                                                        maxMailingsDisplayCount) {
                                        let mailing = mailingList[mailingIndex]
                                        MailingRowItem(
                                            tapAction: { mailingRowSelected(for: mailing) },
                                            mailing: mailing
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }.padding(.horizontal, 20)
        }
        .background(Color.addressableLightGray)
        .ignoresSafeArea(.all, edges: [.bottom])
        .onChange(of: app.pushNotificationEvent) { _ in
            if let pushEvent = app.pushNotificationEvent,
               let mailingId = pushEvent[PushNotificationEvents.mailingListStatus.rawValue],
               let mailing = viewModel.mailings.first(where: { $0.id == mailingId }) {
                mailingRowSelected(for: mailing)
            }
        }
    }
    private func mailingRowSelected(for mailing: Mailing) {
        app.selectedMailing = mailing

        if isIncompleteRadius(mailing) &&
            mailing.mailingStatus != MailingState.canceled.rawValue {
            app.currentView = .composeRadius
        } else {
            selectedMenuItem = .mailingDetail
        }
    }
    private func isIncompleteRadius(_ mailing: Mailing) -> Bool {
        return mailing.relatedMailing == nil && mailing.type == MailingType.radius.rawValue
    }
    private func isSearchTermMatchCountZero() -> Bool {
        var matchCount = 0
        for status in MailingStatus.allCases {
            matchCount += getMailings(with: status).filter { mailing in
                isRelatedToSearchQuery(mailing)
            }.count
        }
        return matchCount == 0
    }
    private func getMailingStatusFromFilters(with status: MailingStatus) -> MailingStatus? {
        return selectedFilters.contains(status.rawValue) ? status : nil
    }
    private func getMailings(with status: MailingStatus) -> [Mailing] {
        switch status {
        case .mailed:
            return viewModel.mailings.filter {
                $0.mailingStatus == MailingState.mailed.rawValue ||
                    $0.mailingStatus == MailingState.remailed.rawValue
            }
        case .processing:
            return viewModel.mailings.filter {
                $0.mailingStatus == MailingState.production.rawValue ||
                    $0.mailingStatus == MailingState.printReady.rawValue ||
                    $0.mailingStatus == MailingState.printing.rawValue ||
                    $0.mailingStatus == MailingState.writeReady.rawValue ||
                    $0.mailingStatus == MailingState.writing.rawValue ||
                    $0.mailingStatus == MailingState.mailReady.rawValue ||
                    $0.mailingStatus == MailingState.productionReady.rawValue
            }
        case .upcoming:
            return viewModel.mailings.filter {
                $0.mailingStatus == MailingState.scheduled.rawValue
            }

        case .draft:
            return viewModel.mailings.filter {
                $0.mailingStatus == MailingState.draft.rawValue ||
                    $0.mailingStatus == MailingState.pending.rawValue ||
                    $0.mailingStatus == MailingState.listReady.rawValue ||
                    $0.mailingStatus == MailingState.listAdded.rawValue ||
                    $0.mailingStatus == MailingState.listApproved.rawValue
            }
        case .archived:
            return viewModel.mailings.filter {
                $0.mailingStatus == MailingState.archived.rawValue ||
                    $0.mailingStatus == MailingState.delivered.rawValue
            }
        case .canceled:
            return viewModel.mailings.filter {
                $0.mailingStatus == MailingState.canceled.rawValue
            }
        }
    }
    private func isRelatedToSearchQuery(_ mailing: Mailing) -> Bool {
        if !mailingSearchTerm.isEmpty {
            return mailing.subjectListEntry?.siteAddressLine1.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .range(of: mailingSearchTerm, options: .caseInsensitive) != nil
        }
        return true
    }
    private func isTouchTwoMailing(_ mailing: Mailing) -> Bool {
        if let relatedTouchMailing = mailing.relatedMailing {
            return relatedTouchMailing.parentMailingID == nil
        } else {
            return false
        }
    }
}

#if DEBUG
struct CampaignsListView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedMenuItem = Binding<MainMenu>(
            get: { MainMenu.campaigns }, set: { _ in }
        )

        CampaignsListView(
            viewModel: CampaignsViewModel(provider: DependencyProvider()),
            selectedMenuItem: selectedMenuItem
        )
    }
}
#endif

// MARK: - MailingRowItem
struct MailingRowItem: View {
    var tapAction: () -> Void
    var mailing: Mailing

    var body: some View {
        Button(action: {
            tapAction()
        }) {
            MailingCardItemView(mailing: mailing)
        }
    }
}
