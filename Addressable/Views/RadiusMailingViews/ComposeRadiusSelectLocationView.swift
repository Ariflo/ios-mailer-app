//
//  ComposeRadiusSelectLocationView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

struct ComposeRadiusSelectLocationView: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel
    @State var locationSelected: Bool = false
    @State var displayTargetCriteriaMenu: Bool = false

    init(viewModel: ComposeRadiusViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let locationEntryBinding = Binding<String>(
            get: {
                viewModel.locationEntry
            }, set: {
                if $0.isEmpty { locationSelected = false }
                viewModel.locationEntry = $0
                viewModel.searchEngine.query = $0
            })
        VStack {
            // MARK: - MapView
            MapboxMapView(selectedCoordinates: viewModel.selectedCoordinates)
            VStack(alignment: .leading) {
                // MARK: - Address Input
                VStack(alignment: .leading, spacing: 15) {
                    Text("Enter the address of the property")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.addressablePurple)
                    VStack {
                        TextField("", text: locationEntryBinding)
                            .textContentType(.fullStreetAddress)
                            .modifier(TextFieldModifier())
                        // MARK: - Address Search Results
                        if !viewModel.locationEntry.isEmpty && !locationSelected {
                            List(viewModel.locationSearchSuggestions, id: \.id) { searchSuggestion in
                                if let addressSuggestion = searchSuggestion.address?.formattedAddress(style: .medium) {
                                    Button(action: {
                                        // Location Selected
                                        viewModel.searchEngine.select(suggestion: searchSuggestion)
                                        viewModel.locationEntry = addressSuggestion
                                        locationSelected = true
                                        hideKeyboard()
                                    }) {
                                        Text(addressSuggestion)
                                            .font(Font.custom("Silka-Medium", size: 14))
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .frame(minWidth: 295, minHeight: 84)
                        }
                    }
                    // MARK: - Targeting Criteria Button
                    Button(action: {
                        displayTargetCriteriaMenu = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "slider.horizontal.3")
                                .frame(maxWidth: 24, maxHeight: 24)
                                .padding(.leading, 18)
                                .foregroundColor(Color.black)
                            Text("Targeting Criteria")
                                .font(Font.custom("Silka-Medium", size: 13))
                                .foregroundColor(Color.black)
                            Spacer()
                            Text("View")
                                .font(Font.custom("Silka-Regular", size: 14))
                                .foregroundColor(Color.black.opacity(0.3))
                                .padding(.trailing, 20)
                        }
                    }
                    .frame(minWidth: 295, minHeight: 54)
                    .background(Color.white)
                    .cornerRadius(5)
                }
            }.padding(40)
        }
        .sheet(isPresented: $displayTargetCriteriaMenu) {
            TargetCriteriaMenuView(viewModel: viewModel)
        }
    }
}

#if DEBUG
struct ComposeRadiusSelectLocationView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusSelectLocationView(
            viewModel: ComposeRadiusViewModel(
                provider: DependencyProvider(),
                selectedMailing: nil
            )
        )
    }
}
#endif
