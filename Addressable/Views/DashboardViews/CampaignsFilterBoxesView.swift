//
//  CampaignsFilterBoxesView.swift
//  Addressable
//
//  Created by Ari on 6/3/21.
//
// swiftlint:disable trailing_closure
import SwiftUI

struct CampaignsFilterBoxesView: View {
    var filterCases: [String]
    @Binding var selectedFilters: [String]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                var width = CGFloat.zero
                var height = CGFloat.zero

                ForEach(filterCases, id: \.self) { filter in
                    Button(action: {
                        // Set filter
                        if let selectedIndex = selectedFilters.firstIndex(of: filter) {
                            selectedFilters.remove(at: selectedIndex)
                        } else {
                            selectedFilters.append(filter)
                        }
                    }) {
                        HStack(spacing: 4) {
                            getFilterImage(for: filter)
                                .imageScale(.small)
                            Text(filter)
                                .font(Font.custom("Silka-Medium", size: 12))
                            filterCases == selectedFilters ?
                                Image(systemName: "xmark")
                                .imageScale(.small)
                                .foregroundColor(Color.addressableFadedBlack)
                                .padding(.leading, 4)
                                .opacity(0.3)
                                : nil
                        }
                        .padding(4)
                        .foregroundColor(selectedFilters.contains(filter) ?
                                            Color.black :
                                            Color.addressableDarkGray)
                        .cornerRadius(3)
                    }
                    .background(selectedFilters.contains(filter) ? Color.white : Color.addressableLighterGray)
                    .padding(.init(top: 4, leading: 0, bottom: 0, trailing: 5))
                    .alignmentGuide(.leading, computeValue: { value in
                        if abs(width - value.width) > geometry.size.width {
                            width = 0
                            height -= value.height
                        }
                        let result = width

                        if let last = filterCases.last {
                            if filter == last {
                                width = 0 // last item
                            } else {
                                width -= value.width
                            }
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height

                        if let last = filterCases.last {
                            if filter == last {
                                height = 0 // last item
                            }
                        }
                        return result
                    })
                }
            }
        }
    }
    private func getFilterImage(for filter: String) -> Image {
        for status in MailingStatus.allCases where status.rawValue == filter {
            switch status {
            case .mailed:
                return Image(systemName: "envelope")
            case .processing:
                return Image(systemName: "arrow.2.circlepath.circle")
            case .upcoming:
                return Image(systemName: "tray.full")
            case .draft:
                return Image(systemName: "doc.plaintext")
            case .archived:
                return Image(systemName: "archivebox")
            }
        }
        return Image(systemName: "exclamationmark.triangle")
    }
}

struct CampaignsFilterBoxesView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedFiltersPreview = Binding<[String]>(
            get: { [""] }, set: { _ in }
        )
        CampaignsFilterBoxesView(
            filterCases: ["Mailed"],
            selectedFilters: selectedFiltersPreview
        )
    }
}
