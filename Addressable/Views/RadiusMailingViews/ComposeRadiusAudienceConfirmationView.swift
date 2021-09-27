//
//  ComposeRadiusAudienceConfirmationView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

struct ComposeRadiusAudienceConfirmationView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: ComposeRadiusViewModel

    @State var expandRecipientList: Bool = false


    init(viewModel: ComposeRadiusViewModel) {
        self.viewModel = viewModel

        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UITableView.appearance().showsVerticalScrollIndicator = false
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            if !expandRecipientList {
                VStack {
                    Text(viewModel.step.rawValue)
                        .font(Font.custom("Silka-Medium", size: 22))
                        .padding(.bottom)
                    // MARK: - Count Pill
                    HStack {
                        HStack {
                            Image(systemName: "person.3")
                            if let targetQuantity = viewModel.touchOneMailing?.targetQuantity {
                                Text("\(targetQuantity)")
                                    .font(Font.custom("Silka-Medium", size: 18))
                            }
                        }
                        .padding(.horizontal, 19)
                        .padding(.vertical, 6)
                    }
                    .background(Color.addressableDarkerGray)
                    .cornerRadius(50.0)
                    .frame(minWidth: 98, minHeight: 34)
                    // MARK: - Instructions
                    Text("Feel free to remove any that you feel aren't suitable. " +
                            "They will be replaced with alternatives to ensure you get the same reach")
                        .font(Font.custom("Silka-Regular", size: 12))
                        .padding()
                        .foregroundColor(Color.addressableFadedBlack)
                        .lineSpacing(2)
                        .multilineTextAlignment(.center)
                }
            }
            // MARK: - Recipient List
            if viewModel.touchOneMailing != nil {
                // swiftlint:disable force_unwrapping
                let selectedMailingBinding = Binding<Mailing>(
                    get: { viewModel.touchOneMailing! },
                    set: { updatedMailing in
                        viewModel.touchOneMailing = updatedMailing
                    })
                // HACK: Consider allowing users to select audience in Radius Creation
                let activeSheetTypeBinding = Binding<MailingDetailSheetTypes?>(
                    get: { nil },
                    set: { _ in })
                let drag = DragGesture()
                    .onEnded { _ in
                        withAnimation(.easeInOut) {
                            self.expandRecipientList.toggle()
                        }
                    }
                MailingRecipientsListView(
                    viewModel: MailingRecipientsListViewModel(
                        provider: app.dependencyProvider,
                        selectedMailing: selectedMailingBinding,
                        numActiveRecipients: $viewModel.numActiveRecipients
                    ),
                    activeSheetType: activeSheetTypeBinding
                )
                .equatable()
                .gesture(drag)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .padding(.horizontal, 40)
    }
}

#if DEBUG
struct ComposeRadiusAudienceConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusAudienceConfirmationView(
            viewModel: ComposeRadiusViewModel(
                provider: DependencyProvider(),
                selectedMailing: nil)
        )
    }
}
#endif
