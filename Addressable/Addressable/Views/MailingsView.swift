//
//  MailingsView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

struct MailingsView: View {
    @ObservedObject var viewModel: MailingsViewModel
    @State var navigateToComposeMail = false

    init(viewModel: MailingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    // TODO: Integrate Listing Radius Mailing
                    List {
                        Section(
                            header:
                                CustomHeader(
                                    name: "Cards and Batches",
                                    image: Image(systemName: "mail.stack"),
                                    backgroundColor: Color(red: 232 / 255, green: 104 / 255, blue: 81 / 255)
                                )
                        ) {
                            ForEach(viewModel.customNotes) { customNote in
                                Text("\((customNote.toFirstName == nil || customNote.toFirstName!.isEmpty)  ? "Batch of \(customNote.batchSize) Notes" : customNote.toFirstName!)").padding()
                            }
                        }
                        .listRowInsets(.init())
                    }
                    .listStyle(PlainListStyle())
                }, size: geometry.size) {
                    viewModel.getCustomNotes()
                }
            }
            .background(
                NavigationLink(destination: ComposeMailingView(
                                viewModel: ComposeMailingViewModel(addressableDataFetcher: AddressableDataFetcher())).navigationBarHidden(true),
                               isActive: $navigateToComposeMail) {}
            )
            .onAppear {
                viewModel.getCustomNotes()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            navigateToComposeMail = true
                        }
                    ) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255))
                            .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitle("Campaigns")
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

struct MailingsView_Previews: PreviewProvider {
    static var previews: some View {
        MailingsView(viewModel: MailingsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
