//
//  SendFeedbackView.swift
//  Addressable
//
//  Created by Ari on 7/29/21.
//

import SwiftUI

struct SendFeedbackView: View {
    @ObservedObject var viewModel: SendFeedbackViewModel
    @State var feebackSent: Bool = false
    @State var feedbackText: String = ""

    init(viewModel: SendFeedbackViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Feedback Title
                Text("Beta Program Feedback")
                    .font(Font.custom("Silka-Medium", size: 20))
                    .padding()
                if feebackSent {
                    // MARK: - Feedback Complete Message
                    Spacer()
                    Text("Feedback Sent! Please continue to let us know if you run into other issues and thank you " +
                            "for being a part of our beta program.")
                        .font(Font.custom("Silka-Regular", size: 16))
                        .foregroundColor(Color.addressableFadedBlack)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    Spacer()
                } else {
                    // MARK: - Feedback Description
                    Text("Let us know of any issues you encounter or features you would like to see!")
                        .foregroundColor(Color.addressableFadedBlack)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    Text("Please note that for any issues with app functionality, " +
                            "the more information you can provide the better. For significantly " +
                            "pressing problems with the app, an Addressable associate will reach " +
                            "out to resolve the issue via email as soon as possible.")
                        .font(Font.custom("Silka-Regular", size: 16))
                        .foregroundColor(Color.addressableFadedBlack)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                    // MARK: - Feedback TextField
                    MultilineTextView(text: $feedbackText)
                        .modifier(TextFieldModifier())
                    // MARK: - Confirm Edit Buttons
                    HStack {
                        Spacer()
                        Text("Submit Feedback")
                            .font(Font.custom("Silka-Medium", size: 16))
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 145, minHeight: 40)
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                            .onTapGesture {
                                viewModel.sendFeedback(feedbackText: feedbackText) { feedbackResponse in
                                    guard feedbackResponse != nil else { return }
                                    feebackSent = true
                                }
                            }
                            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                        Spacer()
                    }.padding()
                }
            }.padding(.horizontal, 20)
        }
    }
}
