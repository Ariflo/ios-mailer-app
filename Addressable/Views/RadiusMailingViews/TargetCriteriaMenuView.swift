//
//  TargetCriteriaMenuView.swift
//  Addressable
//
//  Created by Ari on 4/24/21.
//

import SwiftUI

let kSliderPadding = CGFloat(8.0)

enum CriteriaMenuOptions: String {
    case homeValue = "Home Value"
    case bedCount = "Bed Count"
    case bathCount = "Bath Count"
    case livingArea = "Living Area (Sqft)"
    case yearBuilt = "Year Built"
    case lotSize = "Lot Size (Sqft)"
    case landUse = "Land Use"
    case percentEquity = "Percent Equity"
    case yearsOwned = "Years Owned"
    case ownerPresence = "Owner Presence"
    case zipcode = "Zipcode(s)"
    case city = "City"
}

struct TargetCriteriaMenuView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ComposeRadiusViewModel

    @State var regionZipcodes: String = ""
    @State var regionCity: String = ""

    init(viewModel: ComposeRadiusViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Targeting Criteria").font(Font.custom("Silka-Medium", size: 18)).fontWeight(.bold)
                    // MARK: - Home Value Range
                    TargetCriteriaSliderView(
                        viewModel: viewModel,
                        menuOption: .homeValue
                    )
                    // MARK: - Bed Count Range
                    TargetCriteriaSliderView(
                        viewModel: viewModel,
                        menuOption: .bedCount
                    )
                    // MARK: - Bath Count Range
                    TargetCriteriaSliderView(
                        viewModel: viewModel,
                        menuOption: .bathCount
                    )
                    // MARK: - Living Area Range
                    TargetCriteriaSliderView(
                        viewModel: viewModel,
                        menuOption: .livingArea
                    )
                    // MARK: - Year Built Range
                    TargetCriteriaSliderView(
                        viewModel: viewModel,
                        menuOption: .yearBuilt
                    )
                    // MARK: - Lot Size Range
                    TargetCriteriaSliderView(
                        viewModel: viewModel,
                        menuOption: .lotSize
                    )
                    // MARK: - Landuse Options
                    VStack(alignment: .center, spacing: 15) {
                        Text(CriteriaMenuOptions.landUse.rawValue).font(Font.custom("Silka-Medium", size: 14))
                        HStack(spacing: 10) {
                            CheckView(
                                isChecked: viewModel.dataTreeSearchCriteria.landUseSingleFamily,
                                title: "Single Family") {
                                viewModel.dataTreeSearchCriteria.landUseSingleFamily.toggle()
                            }.multilineTextAlignment(.center)
                            CheckView(
                                isChecked: viewModel.dataTreeSearchCriteria.landUseCondos,
                                title: "Condos") {
                                viewModel.dataTreeSearchCriteria.landUseCondos.toggle()
                            }.multilineTextAlignment(.center)
                            CheckView(
                                isChecked: viewModel.dataTreeSearchCriteria.landUseMultiFamily,
                                title: "Multi-Family") {
                                viewModel.dataTreeSearchCriteria.landUseMultiFamily.toggle()
                            }.multilineTextAlignment(.center)
                            CheckView(
                                isChecked: viewModel.dataTreeSearchCriteria.landUseVacantLot,
                                title: "Vacant Lot") {
                                viewModel.dataTreeSearchCriteria.landUseVacantLot.toggle()
                            }.multilineTextAlignment(.center)
                        }
                    }
                }.padding()
                VStack(alignment: .leading, spacing: 15) {
                    Text("Owner Characteristics").font(Font.custom("Silka-Medium", size: 18)).fontWeight(.bold)
                    VStack(alignment: .center, spacing: 15) {
                        // MARK: - Percent Equity Range
                        TargetCriteriaSliderView(
                            viewModel: viewModel,
                            menuOption: .percentEquity
                        )
                        // MARK: - Years Owned Range
                        TargetCriteriaSliderView(
                            viewModel: viewModel,
                            menuOption: .yearsOwned
                        )
                        // MARK: - Owner Presence
                        VStack(alignment: .center, spacing: 15) {
                            Text(CriteriaMenuOptions.ownerPresence.rawValue).font(Font.custom("Silka-Medium", size: 14))
                            HStack(spacing: 10) {
                                CheckView(
                                    isChecked: viewModel.dataTreeSearchCriteria.ownerOccupiedOccupied,
                                    title: "Owner Occupied") {
                                    viewModel.dataTreeSearchCriteria.ownerOccupiedOccupied.toggle()
                                }.multilineTextAlignment(.center)
                                CheckView(
                                    isChecked: viewModel.dataTreeSearchCriteria.ownerOccupiedAbsentee,
                                    title: "Absentee Owner") {
                                    viewModel.dataTreeSearchCriteria.ownerOccupiedAbsentee.toggle()
                                }.multilineTextAlignment(.center)
                            }
                        }
                    }
                }.padding()
                VStack(alignment: .leading, spacing: 15) {
                    Text("The Region").font(Font.custom("Silka-Medium", size: 18)).fontWeight(.bold)
                    // MARK: - Zipcode
                    VStack {
                        HStack {
                            Text(CriteriaMenuOptions.zipcode.rawValue)
                                .font(Font.custom("Silka-Medium", size: 14))
                                .opacity(viewModel.dataTreeSearchCriteria.includeZipcodes ? 1 : 0.6)
                            Spacer()
                            CheckView(
                                isChecked: viewModel.dataTreeSearchCriteria.includeZipcodes,
                                title: "Include") {
                                viewModel.dataTreeSearchCriteria.includeZipcodes.toggle()
                            }
                        }
                        TextField(CriteriaMenuOptions.zipcode.rawValue,
                                  text: $viewModel.dataTreeSearchCriteria.zipcodes)
                            .modifier(TextFieldModifier())
                            .font(Font.custom("Silka-Medium", size: 14))
                            .border(Color.addressableLightestGray)
                            .textContentType(.fullStreetAddress)
                            .disabled(!viewModel.dataTreeSearchCriteria.includeZipcodes)
                            .opacity(viewModel.dataTreeSearchCriteria.includeZipcodes ? 1 : 0.6)
                    }
                    // MARK: - City
                    VStack {
                        HStack {
                            Text(CriteriaMenuOptions.city.rawValue)
                                .font(Font.custom("Silka-Medium", size: 14))
                                .opacity(viewModel.dataTreeSearchCriteria.includeCities ? 1 : 0.6)
                            Spacer()
                            CheckView(
                                isChecked: viewModel.dataTreeSearchCriteria.includeCities,
                                title: "Include") {
                                viewModel.dataTreeSearchCriteria.includeCities.toggle()
                            }
                        }
                        TextField(CriteriaMenuOptions.city.rawValue, text: $viewModel.dataTreeSearchCriteria.city)
                            .modifier(TextFieldModifier())
                            .font(Font.custom("Silka-Medium", size: 14))
                            .border(Color.addressableLightestGray)
                            .textContentType(.fullStreetAddress)
                            .disabled(!viewModel.dataTreeSearchCriteria.includeCities)
                            .opacity(viewModel.dataTreeSearchCriteria.includeCities ? 1 : 0.6)
                    }
                }.padding()
                HStack(spacing: 14) {
                    Button(action: {
                        // Reset Criteria
                        viewModel.getDataTreeDefaultSearchCriteria()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(Font.custom("Silka-Medium", size: 18))
                            .padding()
                            .foregroundColor(Color.addressableDarkGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.addressableDarkGray, lineWidth: 1)
                            )
                            .multilineTextAlignment(.center)
                    }
                    Button(action: {
                        // Release to Production
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Apply")
                            .font(Font.custom("Silka-Medium", size: 18))
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(viewModel.isEditingTargetDropDate)
                    .opacity(viewModel.isEditingTargetDropDate ? 0.4 : 1)
                }
            }
            .navigationBarTitle("Building Your List")
        }
    }
}

#if DEBUG
struct TargetCriteriaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TargetCriteriaMenuView(viewModel: ComposeRadiusViewModel(
                                provider: DependencyProvider(),
                                selectedMailing: nil)
        )
    }
}
#endif
