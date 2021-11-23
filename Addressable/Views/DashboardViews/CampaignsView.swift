//
//  CampaignsView.swift
//  Addressable
//
//  Created by Ari on 5/24/21.
//

import SwiftUI

enum ComposeMailingOption: String, CaseIterable {
    case radius = "Radius Mailer"
    case sphere = "Sphere"
    case audience = "Audience"
    case single = "Single Card"
}

enum CampaignsStat: String, CaseIterable {
    case campaigns = "Campaigns"
    case cards = "Cards"
    case calls = "Calls"
    case sms = "SMS"
}

struct CampaignsView: View, Equatable {
    static func == (lhs: CampaignsView, rhs: CampaignsView) -> Bool {
        lhs.selectedMenuItem == rhs.selectedMenuItem
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CampaignsViewModel

    @Binding var selectedMenuItem: MainMenu
    @Binding var showSmartNumberWarning: Bool

    @State var showRadiusMenuOption = false
    @State var showSphereMenuOption = false
    @State var showAudienceOption = false
    @State var showSingleMenuOption = false
    @State var hideCreateButton = false

    init(viewModel: CampaignsViewModel, selectedMenuItem: Binding<MainMenu>, showSmartNumberWarning: Binding<Bool>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
        self._showSmartNumberWarning = showSmartNumberWarning
    }

    var body: some View {
        ZStack {
            if viewModel.loadingLeads ||
                viewModel.loadingLeadsWithMessages ||
                viewModel.loadingMailings ||
                viewModel.loadingLeads {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }.frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                )
            } else {
                VStack(spacing: 6) {
                    // MARK: - Untagged Leads Header
                    if viewModel.numOfUntaggedLeads > 0 &&
                        !viewModel.loadingLeads &&
                        app.callManager?.currentActiveCall == nil {
                        Button(action: {
                            selectedMenuItem = .calls
                            viewModel.analyticsTracker.trackEvent(
                                .mobileUntaggedLeadsBannerTapped,
                                context: app.persistentContainer.viewContext
                            )
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .imageScale(.medium)
                                    .padding(.leading, 8)
                                Text("\(viewModel.numOfUntaggedLeads) Recent Untagged " +
                                        "Lead\(viewModel.numOfUntaggedLeads > 1 ? "s" : "")")
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
                    }
                    // MARK: - Campaigns Overview Header
                    if !viewModel.loadingLeads &&
                        !viewModel.loadingLeadsWithMessages &&
                        !viewModel.loadingMailings {
                        HStack {
                            ForEach(CampaignsStat.allCases, id: \.self) { stat in
                                switch stat {
                                case .campaigns:
                                    VStack(spacing: 6) {
                                        Text(String(describing: viewModel.numOfCampaigns))
                                            .font(Font.custom("Silka-Medium", size: 16))
                                            .foregroundColor(Color.addressableFadedBlack)
                                        Text(String(describing: stat.rawValue))
                                            .font(Font.custom("Silka-Bold", size: 14))
                                    }.padding(12)
                                case .cards:
                                    Spacer()
                                    VStack(spacing: 6) {
                                        Text(String(describing: viewModel.numOfCards))
                                            .font(Font.custom("Silka-Medium", size: 16))
                                            .foregroundColor(Color.addressableFadedBlack)
                                        Text(String(describing: stat.rawValue))
                                            .font(Font.custom("Silka-Bold", size: 14))
                                    }.padding(12)
                                case .calls:
                                    Spacer()
                                    VStack(spacing: 6) {
                                        Text(String(describing: viewModel.numOfCalls))
                                            .font(Font.custom("Silka-Medium", size: 16))
                                            .foregroundColor(Color.addressableFadedBlack)
                                        Text(String(describing: stat.rawValue))
                                            .font(Font.custom("Silka-Bold", size: 14))
                                    }.padding(12)
                                case .sms:
                                    Spacer()
                                    VStack(spacing: 6) {
                                        Text(String(describing: viewModel.numOfTextMessages))
                                            .font(Font.custom("Silka-Medium", size: 16))
                                            .foregroundColor(Color.addressableFadedBlack)
                                        Text(String(describing: stat.rawValue))
                                            .font(Font.custom("Silka-Bold", size: 14))
                                    }.padding(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .foregroundColor(Color.addressablePurple)
                    }
                    // MARK: - List of Campaigns
                    if !viewModel.loadingMailings {
                        CampaignsListView(
                            viewModel: viewModel,
                            selectedMenuItem: $selectedMenuItem,
                            hideCreateButton: $hideCreateButton
                        )
                        .environmentObject(app)
                    }
                }
                // MARK: - Add Campaign Button
                ZStack(alignment: .bottomTrailing) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            ForEach(ComposeMailingOption.allCases, id: \.self) { menuOption in
                                switch menuOption {
                                case .radius:
                                    if showRadiusMenuOption {
                                        Button(action: {
                                            app.currentView = .composeRadius
                                            app.selectedMailing = nil
                                            viewModel.analyticsTracker.trackEvent(
                                                .mobileAddRadiusMailingTapped,
                                                context: app.persistentContainer.viewContext
                                            )
                                        }) {
                                            AddMenuItem(icon: "mappin.and.ellipse", label: menuOption.rawValue)
                                        }
                                    }
                                case .sphere:
                                    if showSphereMenuOption {
                                        Button(action: {
                                            // Navigate to Sphere view
                                            viewModel.analyticsTracker.trackEvent(
                                                .mobileAddSphereMailingTapped,
                                                context: app.persistentContainer.viewContext
                                            )
                                        }) {
                                            AddMenuItem(icon: "globe", label: menuOption.rawValue, isComingSoon: true)
                                        }
                                        .opacity(0.4)
                                        .disabled(true)
                                    }
                                case .audience:
                                    if showAudienceOption {
                                        Button(action: {
                                            // Navigate to Audience view
                                            viewModel.analyticsTracker.trackEvent(
                                                .mobileAddAudienceMailingTapped,
                                                context: app.persistentContainer.viewContext
                                            )
                                        }) {
                                            AddMenuItem(
                                                icon: "person.3",
                                                label: menuOption.rawValue,
                                                isComingSoon: true
                                            )
                                        }
                                        .opacity(0.4)
                                        .disabled(true)
                                    }
                                case .single:
                                    if showSingleMenuOption {
                                        Button(action: {
                                            // Navigate to Single Card view
                                            viewModel.analyticsTracker.trackEvent(
                                                .mobileAddSingleMailingTapped,
                                                context: app.persistentContainer.viewContext
                                            )
                                        }) {
                                            AddMenuItem(icon: "mail", label: menuOption.rawValue, isComingSoon: true)
                                        }
                                        .opacity(0.4)
                                        .disabled(true)
                                    }
                                }
                            }
                        }
                        .background(Color.addressableLightGray)
                        .cornerRadius(10)

                        !hideCreateButton ? Button(action: {
                            // Display Add Campaign Menu Options
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    showMenu()
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .foregroundColor(Color.addressablePurple)
                                .background(Color.white)
                                .cornerRadius(50)
                                .shadow(color: .gray, radius: 0.2, x: 1, y: 1)
                        }.transition(.move(edge: .trailing)) : nil
                    }.padding()
                }
            }
        }.onAppear {
            viewModel.getLeads()
            viewModel.getIncomingLeadsWithMessages()
            viewModel.getAllMailingCampaigns()

            if !app.pushEvents.isEmpty {
                app.updateBadgeCount(with: app.pushEvents.filter {
                    $0.mailingListStatus == nil
                })
            }
        }
        .alert(isPresented: $showSmartNumberWarning) {
            Alert(
                title: Text("Smart Number Forwarding"),
                message: Text("All telephoney related features (ie. Calls, Messages, QR code scans) " +
                                "will be forwarded to this device via this app." +
                                " If you are not the primary user please tap on the " +
                                "hamburger menu > tap 'Profile' > Toggle 'Account Primary User' Off immediately.")
            )
        }
    }
    private func showMenu() {
        withAnimation {
            showRadiusMenuOption.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                showSphereMenuOption.toggle()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                showAudienceOption.toggle()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showSingleMenuOption.toggle()
            }
        }
        viewModel.analyticsTracker.trackEvent(
            .mobileAddPlusButtonTapped,
            context: app.persistentContainer.viewContext
        )
    }
}
