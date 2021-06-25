//
//  CustomSegmentedPickerView.swift
//  Addressable
//
//  Created by Ari on 3/5/21.
//

import SwiftUI

struct CustomSegmentedPickerView: View {
    @ObservedObject var viewModel: TagIncomingLeadViewModel

    @State var selectedIndex = 0
    @State private var frames = [CGRect](repeating: .zero, count: 3)

    let tagOptions: [IncomingLeadTagOptions]

    init(viewModel: TagIncomingLeadViewModel, tagOptions: [IncomingLeadTagOptions] ) {
        self.viewModel = viewModel
        self.tagOptions = tagOptions
    }

    var body: some View {
        VStack {
            ZStack {
                HStack(spacing: 10) {
                    ForEach(tagOptions.indices, id: \.self) { index in
                        Button(action: {
                            selectedIndex = index
                            switch tagOptions[index] {
                            case .person, .spam:
                                viewModel.isRealOrSpamSelectedTag = tagOptions[index]
                            case .lowInterest, .fair, .lead:
                                viewModel.isInterestedSelectedTag = tagOptions[index]
                            case .removeYes, .removeNo:
                                viewModel.isRemovalSelectedTag = tagOptions[index]
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
        }
    }

    func setFrame(index: Int, frame: CGRect) {
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
