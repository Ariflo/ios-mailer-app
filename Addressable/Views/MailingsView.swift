//
//  MailingsView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI
import GooglePlaces

struct MailingsView: View {
    @ObservedObject var viewModel: MailingsViewModel
    @State var navigateToComposeMail = false
    @State var navigateToComposeRadiusMailing = false

    init(viewModel: MailingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    List {
                        //                        TODO: Add Single Note Sendoffs in v2.0.0
                        //                        Section(
                        //                            header:
                        //                                CustomHeader(
                        //                                    name: "Cards and Batches",
                        //                                    image: Image(systemName: "mail.stack"),
                        //                                    backgroundColor: Color(red: 232 / 255, green: 104 / 255, blue: 81 / 255)
                        //                                )
                        //                        ) {
                        //                            ForEach(viewModel.customNotes) { customNote in
                        //                                Text("\(customNote.toFirstName.isEmpty  ? "Batch of \(customNote.batchSize) Notes" : customNote.toFirstName) \(customNote.toLastName)").padding()
                        //                            }
                        //                        }
                        //                        .listRowInsets(.init())
                        Section(
                            header:
                                CustomHeader(
                                    name: "Radius Mailings",
                                    image: Image(systemName: "mappin.and.ellipse"),
                                    backgroundColor: Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255)
                                )
                        ) {
                            ForEach(viewModel.radiusMailings, id: \.parentMailingID) { radiusMailing in
                                Button(action: {
                                    guard radiusMailing.listCount > 0 && radiusMailing.status != "list_approved" else { return }
                                    viewModel.selectedRadiusMailing = radiusMailing
                                    navigateToComposeRadiusMailing = true
                                }) {
                                    HStack(alignment: .top) {
                                        Text("\(radiusMailing.name)")
                                            .padding()
                                        Spacer()
                                        Text("\(getRadiusMailingListStatus(radiusMailing))")
                                            .padding()
                                    }
                                }
                            }
                        }
                        .listRowInsets(.init())
                    }
                    .listStyle(PlainListStyle())
                }, size: geometry.size) {
                    viewModel.getAllMailingCampaigns()
                }
            }
            .background(
                NavigationLink(destination: ComposeMailingView(
                                viewModel: ComposeMailingViewModel(addressableDataFetcher: AddressableDataFetcher())).navigationBarHidden(true),
                               isActive: $navigateToComposeMail) {}
            )
            .background(
                NavigationLink(destination: ComposeRadiusMailingView(viewModel:
                                                                        ComposeRadiusMailingViewModel(selectedRadiusMailing: viewModel.selectedRadiusMailing)
                ).navigationBarHidden(true),
                isActive: $navigateToComposeRadiusMailing) {}
            )
            .onAppear {
                viewModel.getAllMailingCampaigns()
            }
            .toolbar {
                //                TODO: Add Single Note Sendoffs in v2.0.0
                //                ToolbarItem(placement: .navigationBarTrailing) {
                //                    Button(
                //                        action: {
                //                            navigateToComposeMail = true
                //                        }
                //                    ) {
                //                        Image(systemName: "square.and.pencil")
                //                            .font(.system(size: 60))
                //                            .foregroundColor(Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255))
                //                            .padding(.top, 8)
                //                    }
                //                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            if viewModel.selectedRadiusMailing != nil {
                                viewModel.selectedRadiusMailing = nil
                            }
                            navigateToComposeRadiusMailing = true
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
        }
    }

    private func getRadiusMailingListStatus(_ mailing: RadiusMailing) -> String {
        if mailing.listCount > 0 && mailing.status != "list_approved" {
            if mailing.targetQuantity > mailing.activeRecipientCount {
                return "\(mailing.activeRecipientCount) (missing \(mailing.targetQuantity - mailing.activeRecipientCount))"
            } else if mailing.targetQuantity < mailing.activeRecipientCount {
                return "surplus of \(mailing.activeRecipientCount - mailing.targetQuantity)!"
            }
        } else if mailing.status == "list_approved" {
            return "List Approved by Customer"
        }
        return "List Pending"
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

struct MailingsView_Previews: PreviewProvider {
    static var previews: some View {
        MailingsView(viewModel: MailingsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
