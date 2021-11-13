//
//  DashboardView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

enum MainMenu: String, CaseIterable {
    case campaigns, calls, messages, profile, mailingDetail, feedback
}

struct DashboardView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: DashboardViewModel

    @State var showNavMenu = false
    @State var displayIncomingLeadSurvey: Bool = false
    @State var showSmartNumberWarning: Bool = false
    @State var selectedMenuItem: MainMenu = .campaigns
    @State var subjectLead: IncomingLead?

    var isComingFromSignIn: Bool = false
    var shouldDisplayIncomingLeadSurvey: Bool = false

    init(viewModel: DashboardViewModel, displayIncomingLeadSurvey: Bool, isComingFromSignIn: Bool) {
        self.viewModel = viewModel
        self.shouldDisplayIncomingLeadSurvey = displayIncomingLeadSurvey
        self.isComingFromSignIn = isComingFromSignIn
    }

    var body: some View {
        let drag = DragGesture()
            .onEnded {
                if $0.translation.width > -100 {
                    withAnimation {
                        self.showNavMenu = false
                    }
                }
            }

        return GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                if showNavMenu {
                    NavigationMenuView(
                        showNavMenu: $showNavMenu,
                        selectedMenuItem: $selectedMenuItem
                    ) { menuItem in
                        var menuItemSelectedAnalyticEvent: AnalyticsEventName = .mobileNavigationMenuSelected

                        switch menuItem {
                        case .campaigns:
                            menuItemSelectedAnalyticEvent = .mobileNavigationCampaignsMenuSelected
                        case .calls:
                            menuItemSelectedAnalyticEvent = .mobileNavigationCallsMenuSelected
                        case .messages:
                            menuItemSelectedAnalyticEvent = .mobileNavigationMessagesMenuSelected
                        case .profile:
                            menuItemSelectedAnalyticEvent = .mobileNavigationProfileMenuSelected
                        case .mailingDetail:
                            menuItemSelectedAnalyticEvent = .mobileNavigationMailingDetailSelected
                        case .feedback:
                            menuItemSelectedAnalyticEvent = .mobileNavigationFeedbackMenuSelected
                        }

                        viewModel.analyticsTracker.trackEvent(
                            menuItemSelectedAnalyticEvent,
                            context: app.persistentContainer.viewContext
                        )
                    }
                    .frame(width: geometry.size.width / 2)
                    .transition(.move(edge: .trailing))
                    .zIndex(-1)
                }
                VStack(spacing: 0) {
                    // MARK: - Main Menu Header
                    HStack(alignment: .center) {
                        Button(action: {
                            selectedMenuItem = .campaigns
                            viewModel.analyticsTracker.trackEvent(
                                .mobileNavigationAddressableHeaderTap,
                                context: app.persistentContainer.viewContext
                            )
                        }) {
                            Text("Addressable")
                                .font(Font.custom("Silka-Medium", size: 22))
                                .foregroundColor(Color.addressablePurple)
                        }.disabled(showNavMenu)
                        #if DEBUG || STAGING || SANDBOX
                        if let schemeName = Bundle.main.object(
                            forInfoDictionaryKey: "CURRENT_SCHEME_NAME"
                        ) as? String {
                            Text("(\(schemeName))")
                                .font(Font.custom("Silka-Medium", size: 16))
                                .foregroundColor(Color.addressableFadedBlack)
                        }
                        #endif
                        Spacer()
                        Button(action: {
                            viewModel.analyticsTracker.trackEvent(
                                .mobileNavigationHamburgerMenuTapped,
                                context: app.persistentContainer.viewContext
                            )
                            // Open Side Menu
                            withAnimation {
                                showNavMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                                .foregroundColor(Color.black)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                    // MARK: - Current Call Banner
                    if app.callManager?.currentActiveCall != nil && !displayIncomingLeadSurvey {
                        Button(action: {
                            app.currentView = .activeCall
                            viewModel.analyticsTracker.trackEvent(
                                .mobileReturnToCallBannerTapped,
                                context: app.persistentContainer.viewContext
                            )
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .imageScale(.medium)
                                    .padding(.leading, 8)
                                Text("Return To Call")
                                    .font(Font.custom("Silka-Medium", size: 12))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.black)
                                    .imageScale(.small)
                                    .padding()
                            }.padding(.vertical, 8)
                        }
                        .frame(maxHeight: 34)
                        .foregroundColor(Color.addressablePurple)
                        .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                        .disabled(showNavMenu)
                    }
                    // MARK: - Main Menu
                    switch selectedMenuItem {
                    case .campaigns:
                        CampaignsView(
                            viewModel: CampaignsViewModel(managedObjectContext: app.persistentContainer.viewContext,
                                                          provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem,
                            showSmartNumberWarning: $showSmartNumberWarning
                        )
                        .equatable()
                        .environmentObject(app)
                        .disabled(showNavMenu)
                    case .calls:
                        CallListView(
                            viewModel: CallsViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem,
                            displayIncomingLeadSurvey: $displayIncomingLeadSurvey,
                            lead: $subjectLead
                        )
                        .equatable()
                        .environmentObject(app)
                        .disabled(showNavMenu)
                    case .messages:
                        MessageListView(
                            viewModel: MessagesViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem
                        )
                        .equatable()
                        .environmentObject(app)
                        .disabled(showNavMenu)
                    case .profile:
                        ProfileView(
                            viewModel: ProfileViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem
                        )
                        .equatable()
                        .environmentObject(app)
                        .disabled(showNavMenu)
                    case .mailingDetail:
                        if let mailing = app.selectedMailing {
                            MailingDetailView(
                                viewModel: MailingDetailViewModel(
                                    provider: app.dependencyProvider,
                                    selectedMailing: mailing
                                )
                            )
                            .equatable()
                            .environmentObject(app)
                            .disabled(showNavMenu)
                        }
                    case .feedback:
                        SendFeedbackView(
                            viewModel: SendFeedbackViewModel(
                                provider: app.dependencyProvider
                            )
                        )
                        .environmentObject(app)
                        .disabled(showNavMenu)
                    }
                }
                .offset(x: showNavMenu ? -(geometry.size.width / 2) : 0)
            }
            .ignoresSafeArea(.all, edges: [.bottom])
            .onAppear {
                app.verifyPermissions {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                if let callManager = app.callManager,
                   let knownLead = callManager.getLeadFromLatestCall() {
                    if knownLead.status == "unknown" && shouldDisplayIncomingLeadSurvey {
                        subjectLead = knownLead
                        displayIncomingLeadSurvey = true
                    }
                }

                if let activeCallMailingId = app.callManager?.currentCallerID.relatedMailingId {
                    navigateToMailingDetailView(with: activeCallMailingId)
                }

                // After ending outgoing calls, return to call list
                if let callManager = app.callManager {
                    if !callManager.getIsCurrentCallIncoming() && callManager.currentActiveCall != nil {
                        selectedMenuItem = .calls
                    }
                }
                showSmartNumberWarning = isComingFromSignIn && isSmartNumberEnabled()
            }
            .onChange(of: app.pushNotificationEvent) { _ in
                if let pushEvent = app.pushNotificationEvent {
                    for event in PushNotificationEvents.allCases {
                        switch event {
                        case .mailingListStatus:
                            guard pushEvent.mailingListStatus != nil else { break }
                            selectedMenuItem = .campaigns
                        case .incomingLeadCall:
                            guard pushEvent.incomingLeadCall != nil else { break }
                            selectedMenuItem = .calls
                        case .incomingLeadMessage:
                            guard pushEvent.incomingLeadMessage != nil else { break }
                            selectedMenuItem = .messages
                        }
                    }
                }
            }
            .sheet(isPresented: $displayIncomingLeadSurvey) {
                TagIncomingLeadView(
                    viewModel: TagIncomingLeadViewModel(
                        provider: app.dependencyProvider,
                        lead: $subjectLead
                    )) {
                    displayIncomingLeadSurvey = false
                }.environmentObject(app)
            }
            .gesture(drag)
        }
    }
    private func navigateToMailingDetailView(with mailingId: Int) {
        viewModel.getMailing(with: mailingId) { mailing in
            guard mailing != nil else { return }
            app.selectedMailing = mailing
            selectedMenuItem = .mailingDetail
        }
    }
    private func isSmartNumberEnabled() -> Bool {
        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let userData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            print("isSmartNumberEnabled() fetch user from keystore fetch error")
            return false
        }
        return !user.smartNumbers.isEmpty
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(
            viewModel: DashboardViewModel(provider: DependencyProvider()),
            displayIncomingLeadSurvey: false,
            isComingFromSignIn: false
        )
    }
}
#endif
