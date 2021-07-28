//
//  DashboardView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI
import GooglePlaces

enum MainMenu: String, CaseIterable {
    case campaigns, calls, messages, profile, mailingDetail
}

struct DashboardView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: DashboardViewModel

    @State var showNavMenu = false
    @State var displayIncomingLeadSurvey: Bool = false
    @State var selectedMenuItem: MainMenu = .campaigns
    @State var subjectLead: IncomingLead?

    var shouldDisplayIncomingLeadSurvey: Bool = false

    init(viewModel: DashboardViewModel, displayIncomingLeadSurvey: Bool) {
        self.viewModel = viewModel
        self.shouldDisplayIncomingLeadSurvey = displayIncomingLeadSurvey
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                if showNavMenu {
                    NavigationMenuView(showNavMenu: $showNavMenu, selectedMenuItem: $selectedMenuItem)
                        .frame(width: geometry.size.width / 2)
                        .transition(.move(edge: .trailing))
                        .zIndex(-1)
                }
                VStack {
                    // MARK: - Main Menu Header
                    HStack(alignment: .center) {
                        Button(action: {
                            selectedMenuItem = .campaigns
                        }) {
                            Text("Addressable")
                                .font(Font.custom("Silka-Medium", size: 22))
                                .foregroundColor(Color.addressablePurple)
                        }
                        Spacer()
                        Button(action: {
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
                    if app.callManager?.currentActiveCall != nil {
                        Button(action: {
                            app.currentView = .activeCall
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .imageScale(.large)
                                    .padding(.leading, 8)
                                Text("Return To Call")
                                    .font(Font.custom("Silka-Medium", size: 12))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.black)
                                    .imageScale(.medium)
                                    .padding()
                            }.padding(.bottom, 8)
                        }
                        .frame(maxHeight: 34)
                        .foregroundColor(Color.addressablePurple)
                        .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                    }
                    // MARK: - Main Menu
                    switch selectedMenuItem {
                    case .campaigns:
                        CampaignsView(
                            viewModel: CampaignsViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem
                        )
                        .equatable()
                        .environmentObject(app)
                    case .calls:
                        CallListView(
                            viewModel: CallsViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem,
                            displayIncomingLeadSurvey: $displayIncomingLeadSurvey,
                            lead: $subjectLead
                        )
                        .equatable()
                        .environmentObject(app)
                    case .messages:
                        MessageListView(
                            viewModel: MessagesViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem
                        )
                        .equatable()
                    case .profile:
                        ProfileView(
                            viewModel: ProfileViewModel(provider: app.dependencyProvider),
                            selectedMenuItem: $selectedMenuItem
                        )
                        .equatable()
                        .environmentObject(app)
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
                        }
                    }
                }
                .adaptsToKeyboard()
                .offset(x: showNavMenu ? -(geometry.size.width / 2) : 0)
                .disabled(showNavMenu)
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
        }
    }
    private func navigateToMailingDetailView(with mailingId: Int) {
        viewModel.getRadiusMailing(with: mailingId) { mailing in
            guard mailing != nil else { return }
            app.selectedMailing = mailing
            selectedMenuItem = .mailingDetail
        }
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: DashboardViewModel(provider: DependencyProvider()), displayIncomingLeadSurvey: false)
    }
}
#endif
