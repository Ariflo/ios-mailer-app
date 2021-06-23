//
//  DashboardView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI
import GooglePlaces

struct DashboardView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: DashboardViewModel
    @State var navigateToComposeMail = false

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    List {
                        Section(
                            header:
                                CustomHeader(
                                    name: "Radius Mailings",
                                    image: Image(systemName: "mappin.and.ellipse"),
                                    backgroundColor: Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255)
                                )
                        ) {
                            if viewModel.radiusMailings.isEmpty && !viewModel.loading {
                                HStack {
                                    Spacer()
                                    Text("No Radius Mailings Sent")
                                    Spacer()
                                }
                            } else if viewModel.loading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Spacer()
                                }
                            }
                            ForEach(viewModel.radiusMailings) { radiusMailing in
                                Button(action: {
                                    app.selectedRadiusMailing = radiusMailing
                                    app.currentView = .composeRadius
                                }) {
                                    HStack(alignment: .top) {
                                        Text("\(radiusMailing.name)")
                                            .padding()
                                        Spacer()
                                        Text("\(getRadiusMailingListStatus(radiusMailing))")
                                            .padding()
                                    }
                                }
                                .disabled(radiusMailing.status == MailingStatus.approved.rawValue)
                                .opacity(radiusMailing.status == MailingStatus.approved.rawValue ? 0.8 : 1)
                            }
                        }.listRowInsets(.init())
                    }
                    .listStyle(PlainListStyle())
                }, size: geometry.size) {
                    viewModel.getAllMailingCampaigns()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            if app.selectedRadiusMailing != nil {
                                app.selectedRadiusMailing = nil
                            }
                            app.currentView = .composeRadius
                        }
                    ) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255))
                            .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitle("Campaigns")
        }.onAppear {
            viewModel.getAllMailingCampaigns()
        }
    }

    private func getRadiusMailingListStatus(_ mailing: RadiusMailing) -> String {
        if mailing.status == MailingStatus.approved.rawValue {
            return "In Progress"
        }
        switch mailing.listStatus {
        case ListStatus.new.rawValue:
            return "List Pending"
        case ListStatus.searching.rawValue,
             ListStatus.exporting.rawValue,
             ListStatus.ingesting.rawValue:
            return "Building List"
        case ListStatus.complete.rawValue:
            if !mailing.recipients.isEmpty {
                return "List Ready for Customer Approval"
            }
            return "Requires Target Criteria Update"
        default:
            return "Requires Target Criteria Update"
        }
    }
}

struct CustomHeader: View {
    let name: String
    let image: SwiftUI.Image
    let backgroundColor: Color

    var body: some View {
        HStack {
            image
                .resizable()
                .frame(width: 25, height: 25)
                .scaledToFill()
                .foregroundColor(Color.white)
                .padding()
            Text(name)
                .font(.title2)
                .listRowInsets(.init())
                .foregroundColor(Color.white)
            Spacer()
        }.background(backgroundColor)
    }
}

#if DEBUG
struct MailingsView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: DashboardViewModel(provider: DependencyProvider()))
    }
}
#endif
