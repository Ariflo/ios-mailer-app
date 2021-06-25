//
//  ComposeRadiusConfirmSendView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//
import SwiftUI

// MARK: - ComposeRadiusConfirmSendView
struct ComposeRadiusConfirmSendView: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel

    init(viewModel: ComposeRadiusViewModel) {
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
                                .onDisappear {
                                    viewModel.getMailingInsideCardImageTask.cancel()
                                }
                        } else if viewModel.touchOneInsideCardImageData != nil &&
                                    viewModel.touchTwoInsideCardImageData != nil {
                            CustomNote.CoverImage(imageData: getInsideCardImageData(for: touch))
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
                        if let mailing = viewModel.touchOneMailing {
                            Text("We will send " +
                                    "\(mailing.activeRecipientCount) " +
                                    "cards to \(mailing.activeRecipientCount) " +
                                    "recipients in the vicinity of \(getRadiusMailingSiteAddress()).")
                                .font(Font.custom("Silka-Medium", size: 12))
                                .foregroundColor(Color.addressableFadedBlack)
                        }
                    }.padding(.horizontal, 40)
                }
            }
        }
    }
    private func getInsideCardImageData(for touch: AddressableTouch) -> Data {
        if let image = touch == .touchOne ?
            viewModel.touchOneInsideCardImageData :
            viewModel.touchTwoInsideCardImageData {
            return image
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
