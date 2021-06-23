//
//  TargetCriteriaSliderView.swift
//  Addressable
//
//  Created by Ari on 4/26/21.
//

import SwiftUI
// HACK - Find a better approach when this view is more fleshed out
// swiftlint:disable cyclomatic_complexity
struct TargetCriteriaSliderView: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel
    @StateObject var homeValueSlider = CustomSlider(start: 50000, end: 100000000)
    @StateObject var bedCountSlider = CustomSlider(start: 0, end: 20)
    @StateObject var bathCountSlider = CustomSlider(start: 0, end: 20)
    @StateObject var livingAreaSlider = CustomSlider(start: 0, end: 15000)
    @StateObject var yearBuiltSlider = CustomSlider(
        start: 1900,
        end: Double(Calendar.current.component(.year, from: Date()))
    )
    @StateObject var lotSizeSlider = CustomSlider(start: 1000, end: 100000)
    @StateObject var percentEquitySlider = CustomSlider(start: 0, end: 100)
    @StateObject var yearsOwnedSlider = CustomSlider(start: 0, end: 100)

    var menuOption: CriteriaMenuOptions
    @State var slider = CustomSlider(start: 10, end: 100)

    init(
        viewModel: ComposeRadiusViewModel,
        menuOption: CriteriaMenuOptions
    ) {
        self.viewModel = viewModel
        self.menuOption = menuOption
    }

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                Text("Spacer").foregroundColor(Color.white).opacity(isOptionIncluded() ? 1 : 0.6 )
                VStack(spacing: 5) {
                    Text(menuOption.rawValue).font(Font.custom("Silka-Medium", size: 14))
                    switch menuOption {
                    case .homeValue:
                        Text("$\(Int(slider.lowHandle.currentValue).roundedWithAbbreviations) - " +
                                "$\(Int(slider.highHandle.currentValue).roundedWithAbbreviations)")
                            .font(Font.custom("Silka-Medium", size: 14))
                    case .percentEquity:
                        Text("\(Int(slider.lowHandle.currentValue))% - " +
                                "\(Int(slider.highHandle.currentValue))%")
                            .font(Font.custom("Silka-Medium", size: 14))
                    case .livingArea:
                        Text("\(Int(slider.lowHandle.currentValue).roundedWithAbbreviations) - " +
                                "\(Int(slider.highHandle.currentValue).roundedWithAbbreviations)")
                            .font(Font.custom("Silka-Medium", size: 14))
                    case .lotSize:
                        Text("\(Int(slider.lowHandle.currentValue).roundedToNearestThousandWithAbbrev) - " +
                                "\(Int(slider.highHandle.currentValue).roundedToNearestThousandWithAbbrev)")
                            .font(Font.custom("Silka-Medium", size: 14))
                    default:
                        Text("\(String(Int(slider.lowHandle.currentValue))) - " +
                                "\(String(Int(slider.highHandle.currentValue)))")
                            .font(Font.custom("Silka-Medium", size: 14))
                    }
                }.onReceive(slider.objectWillChange) { _ in
                    // Prevent Handles from overlapping
                    if slider.lowHandle.currentValue > slider.highHandle.currentValue {
                        let currentPositionX = slider.highHandle.currentLocation.x < kSliderPadding ?
                            0 : slider.highHandle.currentLocation.x
                        slider.lowHandle.resetHandlePosition(to: currentPositionX - kSliderPadding)
                    } else {
                        maybeSetCriteriaValues()
                    }
                }
                .opacity(isOptionIncluded() ? 1 : 0.6)
                Spacer()
                CheckView(isChecked: isOptionIncluded(), title: "Include", toggle: toggleIncluded)
            }
            SliderView(slider: slider).opacity(isOptionIncluded() ? 1 : 0.6 ).disabled(!isOptionIncluded())
        }.onAppear {
            slider = getSliderForMenuOption()
            setDefaultValues()
        }
    }
    private func setDefaultValues() {
        switch menuOption {
        case .homeValue:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minValue))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxValue))
        case .percentEquity:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minPercentEquity))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxPercentEquity))
        case .yearsOwned:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minYearsOwned))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxYearsOwned))
        case .bedCount:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minBedCount))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxBedCount))
        case .bathCount:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minBathCount))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxBathCount))
        case .livingArea:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minBuildingArea))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxBuildingArea))
        case .yearBuilt:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minYearBuilt))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxYearBuilt))
        case .lotSize:
            slider.lowHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.minLotSize))
            slider.highHandle.setDefaultValues(to: Double(viewModel.dataTreeSearchCriteria.maxLotSize))
        default:
            print("No slider value for menu option - setDefaultValues()")
        }
    }

    private func getSliderForMenuOption() -> CustomSlider {
        switch menuOption {
        case .homeValue:
            return homeValueSlider
        case .bedCount:
            return bedCountSlider
        case .bathCount:
            return bathCountSlider
        case .livingArea:
            return livingAreaSlider
        case .yearBuilt:
            return yearBuiltSlider
        case .lotSize:
            return lotSizeSlider
        case .percentEquity:
            return percentEquitySlider
        case .yearsOwned:
            return yearsOwnedSlider
        default:
            return CustomSlider(start: 10, end: 100)
        }
    }

    private func maybeSetCriteriaValues() {
        if slider.lowHandle.onDrag || slider.highHandle.onDrag {
            setCriteriaValues()
        }
    }

    private func setCriteriaValues() {
        switch menuOption {
        case .homeValue:
            viewModel.dataTreeSearchCriteria.minValue = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxValue = Int(slider.highHandle.currentValue)
        case .bedCount:
            viewModel.dataTreeSearchCriteria.minBedCount = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxBedCount = Int(slider.highHandle.currentValue)
        case .bathCount:
            viewModel.dataTreeSearchCriteria.minBathCount = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxBathCount = Int(slider.highHandle.currentValue)
        case .livingArea:
            viewModel.dataTreeSearchCriteria.minBuildingArea = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxBuildingArea = Int(slider.highHandle.currentValue)
        case .yearBuilt:
            viewModel.dataTreeSearchCriteria.minYearBuilt = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxYearBuilt = Int(slider.highHandle.currentValue)
        case .lotSize:
            viewModel.dataTreeSearchCriteria.minLotSize = Int(slider.lowHandle.currentValue).roundedToNearestThousand
            viewModel.dataTreeSearchCriteria.maxLotSize = Int(slider.highHandle.currentValue).roundedToNearestThousand
        case .percentEquity:
            viewModel.dataTreeSearchCriteria.minPercentEquity = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxPercentEquity = Int(slider.highHandle.currentValue)
        case .yearsOwned:
            viewModel.dataTreeSearchCriteria.minYearsOwned = Int(slider.lowHandle.currentValue)
            viewModel.dataTreeSearchCriteria.maxYearsOwned = Int(slider.highHandle.currentValue)
        default:
            print("No slider value for menu option - setCriteriaValues()")
        }
    }

    private func isOptionIncluded() -> Bool {
        switch menuOption {
        case .homeValue:
            return viewModel.dataTreeSearchCriteria.includeValue
        case .bedCount:
            return viewModel.dataTreeSearchCriteria.includeBedCount
        case .bathCount:
            return viewModel.dataTreeSearchCriteria.includeBathCount
        case .livingArea:
            return viewModel.dataTreeSearchCriteria.includeBuildingArea
        case .yearBuilt:
            return viewModel.dataTreeSearchCriteria.includeYearBuilt
        case .lotSize:
            return viewModel.dataTreeSearchCriteria.includeLotSize
        case .percentEquity:
            return viewModel.dataTreeSearchCriteria.includePercentEquity
        case .yearsOwned:
            return viewModel.dataTreeSearchCriteria.includeYearsOwned
        default:
            return false
        }
    }

    private func toggleIncluded() {
        switch menuOption {
        case .homeValue:
            viewModel.dataTreeSearchCriteria.includeValue.toggle()
            if viewModel.dataTreeSearchCriteria.includeValue {
                setCriteriaValues()
            }
        case .bedCount:
            viewModel.dataTreeSearchCriteria.includeBedCount.toggle()
            if viewModel.dataTreeSearchCriteria.includeBedCount {
                setCriteriaValues()
            }
        case .bathCount:
            viewModel.dataTreeSearchCriteria.includeBathCount.toggle()
            if viewModel.dataTreeSearchCriteria.includeBathCount {
                setCriteriaValues()
            }
        case .livingArea:
            viewModel.dataTreeSearchCriteria.includeBuildingArea.toggle()
            if viewModel.dataTreeSearchCriteria.includeBuildingArea {
                setCriteriaValues()
            }
        case .yearBuilt:
            viewModel.dataTreeSearchCriteria.includeYearBuilt.toggle()
            if viewModel.dataTreeSearchCriteria.includeYearBuilt {
                setCriteriaValues()
            }
        case .lotSize:
            viewModel.dataTreeSearchCriteria.includeLotSize.toggle()
            if viewModel.dataTreeSearchCriteria.includeLotSize {
                setCriteriaValues()
            }
        case .percentEquity:
            viewModel.dataTreeSearchCriteria.includePercentEquity.toggle()
            if viewModel.dataTreeSearchCriteria.includePercentEquity {
                setCriteriaValues()
            }
        case .yearsOwned:
            viewModel.dataTreeSearchCriteria.includeYearsOwned.toggle()
            if viewModel.dataTreeSearchCriteria.includeYearsOwned {
                setCriteriaValues()
            }
        default:
            print("No slider value for menu option - toggleIncluded()")
        }
    }
}

#if DEBUG
struct TargetCriteriaSliderView_Previews: PreviewProvider {
    static var previews: some View {
        TargetCriteriaSliderView(
            viewModel: ComposeRadiusViewModel(
                provider: DependencyProvider(),
                selectedMailing: nil
            ),
            menuOption: CriteriaMenuOptions.homeValue
        )
    }
}
#endif
