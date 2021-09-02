//
//  SendFeedbackViewModel.swift
//  Addressable
//
//  Created by Ari on 7/29/21.
//

import SwiftUI
import Combine

class SendFeedbackViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    init(provider: DependencyProviding) {
        apiService = provider.register(provider: provider)
    }

    func sendFeedback(feedbackText: String, onCompletion: @escaping (GenericAPISuccessResponse?) -> Void) {
        guard let versionNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
              let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let userData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: userData),
              let sendFeedbackData = try? JSONEncoder().encode(
                FeedbackWrapper(feedback: Feedback(
                                    appVersion: "v\(appVersion) (\(versionNumber))",
                                    feedbackMessage: feedbackText,
                                    userToken: user.authenticationToken)
                )
              ) else {
            print("Encoding Error in sendFeedback()")
            return
        }
        apiService.sendAppFeedback(feedbackData: sendFeedbackData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard self != nil else { return }
                    switch value {
                    case .failure(let error):
                        print("sendAppFeedback() receiveCompletion error: \(error)")
                        onCompletion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] sentFeedbackResponse in
                    guard self != nil else { return }
                    onCompletion(sentFeedbackResponse)
                })
            .store(in: &disposables)
    }
}
