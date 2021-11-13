//
//  ComposeRadiusConfirmSendView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//
import SwiftUI

enum RadiusSocketChannels: String, CaseIterable {
    case insideCardImage = "CardInsideImageChannel"
    case relatedMailing = "RelatedMailingChannel"
}

// MARK: - ComposeRadiusConfirmSendView
struct ComposeRadiusConfirmSendView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: ComposeRadiusViewModel

    init(viewModel: ComposeRadiusViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            Text(viewModel.step.rawValue)
                .font(Font.custom("Silka-Medium", size: 22))
                .padding(.bottom)
            ForEach(AddressableTouch.allCases, id: \.self) { touch in
                VStack(alignment: .leading) {
                    // MARK: - Touch Inside Card Preview
                    HStack(alignment: .center) {
                        Spacer()
                        if !viewModel.canAfford {
                            Text("Please purchase more tokens to create this mailing.")
                                .font(Font.custom("Silka-Medium", size: 12))
                                .foregroundColor(Color.addressableFadedBlack)
                                .multilineTextAlignment(.leading)
                                .frame(width: 350, height: 200)
                        } else if !isCardImageReady(for: touch) {
                            ProgressView("Preview Requested (may take a few minutes)")
                                .progressViewStyle(CircularProgressViewStyle())
                                .font(Font.custom("Silka-Medium", size: 12))
                                .foregroundColor(Color.addressableFadedBlack)
                                .multilineTextAlignment(.leading)
                                .frame(width: 350, height: 200)
                        } else {
                            CustomNote.CoverImage(imageData: getInsideCardImageDataFromStore(for: touch))
                                .frame(maxWidth: 350, maxHeight: 200)
                        }
                        Spacer()
                    }
                    // MARK: - Touch Drop Date + Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text(touch.rawValue).font(Font.custom("Silka-Medium", size: 20))
                            switch touch {
                            case .touchOne:
                                HStack {
                                    if viewModel.isEditingTargetDropDate {
                                        DatePicker(
                                            selection: Binding<Date>(
                                                get: {
                                                    getTargetDropDateObject()
                                                }, set: {
                                                    viewModel.analyticsTracker.trackEvent(
                                                        .mobileUpdateDateRadiusMailing,
                                                        context: app.persistentContainer.viewContext
                                                    )
                                                    viewModel.setSelectedDropDate(selectedDate: $0)
                                                }),
                                            in: getTargetDropDateObject()...,
                                            displayedComponents: .date
                                        ) {}
                                    } else {
                                        Text("\(getFormattedTargetDropDate())")
                                            .font(Font.custom("Silka-Medium", size: 12))
                                            .foregroundColor(Color.addressableFadedBlack)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Button(action: {
                                        viewModel.isEditingTargetDropDate.toggle()
                                    }) {
                                        Text(viewModel.isEditingTargetDropDate ? "Set New Drop Date" : "Edit Drop Date")
                                            .font(Font.custom("Silka-Medium", size: 12))
                                            .foregroundColor(Color.addressableFadedBlack)
                                            .underline()
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            case .touchTwo:
                                if let mailing = viewModel.touchOneMailing {
                                    Text("\(mailing.topicDuration ?? 3) weeks later")
                                        .font(Font.custom("Silka-Medium", size: 12))
                                        .foregroundColor(Color.addressableFadedBlack)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        Text("We will send " +
                                "\(viewModel.numActiveRecipients) " +
                                "cards to \(viewModel.numActiveRecipients) " +
                                "recipients in the vicinity of \(getRadiusMailingSiteAddress()).")
                            .font(Font.custom("Silka-Medium", size: 12))
                            .foregroundColor(Color.addressableFadedBlack)
                            .lineLimit(nil)
                    }.padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            viewModel.connectToSocket()
        }
        .onDisappear {
            viewModel.disconnectFromSocket()
        }
    }
    private func isCardImageReady(for touch: AddressableTouch) -> Bool {
        // swiftlint:disable force_unwrapping
        if touch == .touchOne {
            if viewModel.touchOneMailing?.cardInsidePreviewUrl != nil &&
                viewModel.touchOneInsideCardImageData == nil {
                viewModel.getInsideCardImageData(
                    for: touch,
                    url: (viewModel.touchOneMailing?.cardInsidePreviewUrl!)!
                )
            }
            return viewModel.touchOneInsideCardImageData != nil
        } else {
            if viewModel.touchTwoMailing?.cardInsidePreviewUrl != nil && viewModel.touchTwoInsideCardImageData == nil {
                viewModel.getInsideCardImageData(
                    for: touch,
                    url: (viewModel.touchTwoMailing?.cardInsidePreviewUrl!)!
                )
            }
            return viewModel.touchTwoInsideCardImageData != nil
        }
    }
    private func getInsideCardImageDataFromStore(for touch: AddressableTouch) -> Data {
        if let imageData = touch == .touchOne ?
            viewModel.touchOneInsideCardImageData :
            viewModel.touchTwoInsideCardImageData {
            return imageData
        }
        return Data()
    }
    private func getRadiusMailingSiteAddress() -> String {
        if let mailing = viewModel.touchOneMailing,
           let subjectListEntry = mailing.subjectListEntry {
            return "\(subjectListEntry.siteAddressLine1.trimmingCharacters(in: .whitespacesAndNewlines))" +
                "\(subjectListEntry.siteAddressLine2 ?? "".trimmingCharacters(in: .whitespacesAndNewlines)) " +
                "\(subjectListEntry.siteCity.trimmingCharacters(in: .whitespacesAndNewlines)) " +
                "\(subjectListEntry.siteState.trimmingCharacters(in: .whitespacesAndNewlines)), " +
                "\(subjectListEntry.siteZipcode.trimmingCharacters(in: .whitespacesAndNewlines))"
        } else {
            return ""
        }
    }
    private func getFormattedTargetDropDate() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"

        return dateFormatterPrint.string(from: getTargetDropDateObject())
    }

    private func getTargetDropDateObject() -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatterGet.date(from: viewModel.selectedDropDate) {
            return date
        } else {
            return Date()
        }
    }
}
#if DEBUG
struct ComposeRadiusConfirmSendView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusConfirmSendView(
            viewModel: ComposeRadiusViewModel(
                provider: DependencyProvider(),
                selectedMailing: nil)
        )
    }
}
#endif
