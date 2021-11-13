//
//  SelectAudienceView.swift
//  Addressable
//
//  Created by Ari on 8/9/21.
//

import SwiftUI

enum SelectAudienceViewAlerts {
    case addAudienceConfirmation, error
}

struct SelectAudienceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: SelectAudienceViewModel
    @State var showingAlert: Bool = false
    @State var selectedAlert: SelectAudienceViewAlerts = .addAudienceConfirmation
    @State var selectedAudience: ListUpload?

    init(viewModel: SelectAudienceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.loadingAudiences {
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
                } else if viewModel.audiences.count < 1 && !viewModel.loadingAudiences {
                    Spacer()
                    EmptyListView(message: "No audiences avaliable. " +
                                    "Please reach out to an Addressable administrator or " +
                                    "representative to create audiences to select here and continue."
                    )
                    Spacer()
                } else {
                    List(viewModel.audiences.filter { $0.status == ListUploadStatus.active }) { audience in
                        Button(action: {
                            selectedAudience = audience
                            selectedAlert = .addAudienceConfirmation
                            viewModel.analyticsTracker.trackEvent(
                                .mobileAddAudienceSelection,
                                context: app.persistentContainer.viewContext
                            )
                            showingAlert = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(audience.name)
                                        .font(Font.custom("Silka-Bold", size: 18))
                                    if let creator = audience.createdBy {
                                        Text("Created by: \(creator)")
                                            .font(Font.custom("Silka-Medium", size: 14))
                                    }
                                    Text("Usage Count: \(audience.mailingUsage)")
                                        .font(Font.custom("Silka-Medium", size: 14))
                                    Text("Created: \(audience.createdAt)")
                                        .font(Font.custom("Silka-Medium", size: 14))
                                }
                                Spacer()
                                Text("\(audience.activeCount) Recipients")
                                    .font(Font.custom("Silka-Medium", size: 14))
                            }
                            .padding()
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }.navigationBarTitle("Select Audience", displayMode: .inline)
        }
        .onAppear {
            viewModel.getAudiences()
        }
        .alert(isPresented: $showingAlert) {
            switch selectedAlert {
            case .addAudienceConfirmation:
                if let audience = selectedAudience {
                    return Alert(
                        title: Text("Add \(audience.activeCount) Recipients to Mailing")
                            .font(Font.custom("Silka-Bold", size: 14)),
                        message: Text("Add \(audience.name) to \(viewModel.mailing.name) mailing?")
                            .font(Font.custom("Silka-Medium", size: 12)),
                        primaryButton: .default(Text("Confirm")) {
                            viewModel.addAudience(with: audience.id) { mailingWithAudience in
                                if let newMailing = mailingWithAudience {
                                    viewModel.mailing = newMailing
                                    viewModel.analyticsTracker.trackEvent(
                                        .mobileAddAudienceSelectionSuccess,
                                        context: app.persistentContainer.viewContext
                                    )
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    selectedAlert = .error
                                    showingAlert = true
                                }
                            }
                        }, secondaryButton: .cancel())
                }
                return errorAlert()
            case .error:
                return errorAlert()
            }
        }
    }
    private func errorAlert() -> Alert {
        Alert(title: Text("Sorry something went wrong," +
                            " try again or reach out to an Addressable " +
                            " representative if the problem persists."))
    }
}
