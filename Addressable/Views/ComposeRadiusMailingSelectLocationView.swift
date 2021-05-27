//
//  ComposeRadiusMailingSelectLocationView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

struct ComposeRadiusMailingSelectLocationView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State var locationSelected: Bool = false
    @State var displayTargetCriteriaMenu: Bool = false

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
        UITextField.appearance().clearButtonMode = .whileEditing
    }

    var body: some View {
        let locationEntryBinding = Binding<String>(
            get: {
                viewModel.locationEntry
            }, set: {
                if $0.isEmpty { locationSelected = false }
                viewModel.locationEntry = $0
                viewModel.getPlacesFromQuery(locationQuery: $0)
            })
        VStack {
            // MARK: - MapView
            GoogleMapsView(
                coordinates: (viewModel.latitude, viewModel.longitude),
                locationSelected: locationSelected,
                zoom: locationSelected ? 15.0 : 10.0
            )
            VStack(alignment: .leading) {
                // MARK: - Address Input
                VStack(alignment: .leading, spacing: 15) {
                    Text("Enter the address of the property")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.addressablePurple)
                    VStack(spacing: 0) {
                        TextField("", text: locationEntryBinding)
                            .font(Font.custom("Silka-Medium", size: 12))
                            .padding(.leading, 12)
                            .frame(minWidth: 295, minHeight: 54)
                            .textContentType(.fullStreetAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.addressableLightestGray, lineWidth: 1)
                            )
                        // MARK: - Address Search Results
                        if !viewModel.locationEntry.isEmpty && !locationSelected {
                            List(viewModel.places, id: \.placeID) { place in
                                Button(action: {
                                    locationSelected = true
                                    viewModel.setPlaceOnMap(for: place.placeID)
                                    viewModel.locationEntry = place.attributedFullText.string
                                    viewModel.resetPlacesList()
                                    hideKeyboard()
                                }) {
                                    Text(place.attributedFullText.string)
                                        .font(Font.custom("Silka-Medium", size: 14))
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
        .onAppear {
            viewModel.maybeInitializeMapWithCurrentLocation()
        }
        .sheet(isPresented: $displayTargetCriteriaMenu) {
            TargetCriteriaMenuView(viewModel: viewModel)
        }

    }
}

struct ComposeRadiusMailingSelectLocationView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingSelectLocationView(viewModel: ComposeRadiusMailingViewModel(selectedRadiusMailing: nil))
    }
}
