//
//  ComposeRadiusMailingConfirmSendView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

// MARK: - ComposeRadiusMailingConfirmSendView
struct ComposeRadiusMailingConfirmSendView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            ForEach(AddressableTouch.allCases, id: \.self) { touch in
                VStack(alignment: .leading) {
                    // MARK: - Touch Inside Card Preview
                    HStack(alignment: .center) {
                        Spacer()
                        if viewModel.loadingInsideCardPreview ||
                            (viewModel.touchOneInsideCardImageData == nil &&
                                viewModel.touchTwoInsideCardImageData == nil) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 350, height: 200)
                        } else if viewModel.touchOneInsideCardImageData != nil &&
                                    viewModel.touchTwoInsideCardImageData != nil {
                            CustomNote.CoverImage(imageData: getInsideCardImageData(for: touch))
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
                                        viewModel.isEditingTargetDropDate = !viewModel.isEditingTargetDropDate
                                    }) {
                                        Text(viewModel.isEditingTargetDropDate ? "Set New Drop Date" : "Edit Drop Date")
                                            .font(Font.custom("Silka-Medium", size: 12))
                                            .foregroundColor(Color.addressableFadedBlack)
                                            .underline()
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            case .touchTwo:
                                Text("\(viewModel.touchOneMailing!.topicDuration ?? 3) weeks later")
                                    .font(Font.custom("Silka-Medium", size: 12))
                                    .foregroundColor(Color.addressableFadedBlack)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        Text("We will send " +
                                "\(viewModel.touchOneMailing!.activeRecipientCount) " +
                                "cards to \(viewModel.touchOneMailing!.activeRecipientCount) " +
                                "recipients in the vicinity of \(getRadiusMailingSiteAddress()).")
                            .font(Font.custom("Silka-Medium", size: 12))
                            .foregroundColor(Color.addressableFadedBlack)
                    }.padding(.horizontal, 40)
                }
            }
        }
    }
    private func getInsideCardImageData(for touch: AddressableTouch) -> Data {
        let imageData = touch == .touchOne ?
            viewModel.touchOneInsideCardImageData :
            viewModel.touchTwoInsideCardImageData

        if imageData != nil {
            return imageData!
        }
        return Data()
    }
    private func getRadiusMailingSiteAddress() -> String {
        return "\(viewModel.touchOneMailing!.subjectListEntry.siteAddressLine1.trimmingCharacters(in: .whitespacesAndNewlines))" +
            "\(viewModel.touchOneMailing!.subjectListEntry.siteAddressLine2 ?? "".trimmingCharacters(in: .whitespacesAndNewlines)) " +
            "\(viewModel.touchOneMailing!.subjectListEntry.siteCity.trimmingCharacters(in: .whitespacesAndNewlines)) " +
            "\(viewModel.touchOneMailing!.subjectListEntry.siteState.trimmingCharacters(in: .whitespacesAndNewlines)), " +
            "\(viewModel.touchOneMailing!.subjectListEntry.siteZipcode.trimmingCharacters(in: .whitespacesAndNewlines))"
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
struct ComposeRadiusMailingConfirmSendView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingConfirmSendView(viewModel: ComposeRadiusMailingViewModel(selectedRadiusMailing: nil))
    }
}
