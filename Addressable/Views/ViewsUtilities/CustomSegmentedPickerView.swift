//
//  CustomSegmentedPickerView.swift
//  Addressable
//
//  Created by Ari on 3/5/21.
//

import SwiftUI

struct CustomSegmentedPickerView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: TagIncomingLeadViewModel

    @State var selectedIndex = 0
    @State private var frames = [CGRect](repeating: .zero, count: 3)

    let tagOptions: [IncomingLeadTagOptions]

    init(viewModel: TagIncomingLeadViewModel, tagOptions: [IncomingLeadTagOptions] ) {
        self.viewModel = viewModel
        self.tagOptions = tagOptions
    }

    var body: some View {
        let isRealOrSpamSelectedTagAnalyticEvents: [AnalyticsEventName] = [
            .mobileLeadTaggedPerson, .mobileLeadTaggedSpam
        ]
        let isInterestedSelectedTagAnalyticEvents: [AnalyticsEventName] = [
            .mobileLeadTaggedLowInterest, .mobileLeadTaggedFair, .mobileLeadTaggedLead
        ]
        let isRemovalSelectedTagAnalyticEvents: [AnalyticsEventName] = [
            .mobileLeadTaggedNotRemoval, .mobileLeadTaggedRemoval
        ]
        VStack {
            ZStack {
                HStack(spacing: 10) {
                    ForEach(tagOptions.indices, id: \.self) { index in
                        Button(action: {
                            selectedIndex = index
                            switch tagOptions[index] {
                            case .person, .spam:
                                viewModel.isRealOrSpamSelectedTag = tagOptions[index]
                                viewModel.analyticsTracker.trackEvent(
                                    isRealOrSpamSelectedTagAnalyticEvents[index],
                                    context: app.persistentContainer.viewContext
                                )
                            case .lowInterest, .fair, .lead:
                                viewModel.isInterestedSelectedTag = tagOptions[index]
                                viewModel.analyticsTracker.trackEvent(
                                    isInterestedSelectedTagAnalyticEvents[index],
                                    context: app.persistentContainer.viewContext
                                )
                            case .removeYes, .removeNo:
                                viewModel.isRemovalSelectedTag = tagOptions[index]
                                viewModel.analyticsTracker.trackEvent(
                                    isRemovalSelectedTagAnalyticEvents[index],
                                    context: app.persistentContainer.viewContext
                                )
                            }
                        }) {
                            SegmentedControlIconOptionView(option: tagOptions[index])
                        }.padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20)).background(
                            GeometryReader { geo in
                                Color.clear.onAppear { setFrame(index: index, frame: geo.frame(in: .global)) }
                            }
                        )
                    }
                }
                .background(
                    Capsule().fill(Color.gray.opacity(0.3).opacity(0.4))
                        .frame(
                            width: frames[selectedIndex].width,
                            height: frames[selectedIndex].height,
                            alignment: .topLeading
                        )
                        .offset(x: frames[selectedIndex].minX - frames[0].minX), alignment: .leading
                )
            }
            .animation(.default)
            .background(Capsule().stroke(Color.gray, lineWidth: 1))
        }.onAppear {
            for index in tagOptions.indices where isSelectedTagOption(tag: tagOptions[index]) {
                selectedIndex = index
            }
        }
    }
    private func isSelectedTagOption(tag: IncomingLeadTagOptions) -> Bool {
        return tag == self.viewModel.isInterestedSelectedTag ||
            tag == self.viewModel.isRealOrSpamSelectedTag ||
            tag == self.viewModel.isRemovalSelectedTag
    }

    private func setFrame(index: Int, frame: CGRect) {
        self.frames[index] = frame
    }
}
#if DEBUG
struct CustomSegmentedPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedLead = Binding<IncomingLead?>(
            get: { nil }, set: { _ in }
        )
        CustomSegmentedPickerView(
            viewModel: TagIncomingLeadViewModel(provider: DependencyProvider(), lead: selectedLead),
            tagOptions: [.fair]
        )
    }
}
#endif
