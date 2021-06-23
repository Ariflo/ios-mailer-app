//
//  EditMailingInsideCardViewModel.swift
//  Addressable
//
//  Created by Ari on 6/17/21.
//

import SwiftUI
import Combine


class EditMailingInsideCardViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()
    var messageTemplateId: Int

    @Published var messageTemplateBody: String = ""
    @Published var loadingMessageTemplate: Bool = true

    init(provider: DependencyProviding, templateId: Int) {
        apiService = provider.register(provider: provider)
        messageTemplateId = templateId
    }

    func updateMailingMessageTemplate(
        completion: @escaping (MessageTemplate?) -> Void
    ) {
        guard let encodedMessageTemplateData = try? JSONEncoder().encode(
            OutgoingMessageTemplateWrapper(
                messageTemplate: OutgoingMessageTemplate(title: nil, body: messageTemplateBody)
            )
        ) else {
            print("Update Message Template Encoding Error")
            return
        }

        apiService.updateMessageTemplate(for: messageTemplateId, encodedMessageTemplateData)
            .map { resp in
                resp.messageTemplate
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("updateMailingMessageTemplate(templateBody: \(self.messageTemplateBody)," +
                                " receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { updatedMessageTemplate in
                    completion(updatedMessageTemplate)
                })
            .store(in: &disposables)
    }

    func getMessageTemplate() {
        loadingMessageTemplate = true
        apiService.getMessageTemplate(for: messageTemplateId)
            .map { resp in
                resp.messageTemplate
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMessageTemplate(id: \(self.messageTemplateId) receiveCompletion error: \(error)")
                        self.messageTemplateBody = ""
                        self.loadingMessageTemplate = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] template in
                    guard let self = self else { return }
                    self.messageTemplateBody = template.body
                    self.loadingMessageTemplate = false
                })
            .store(in: &disposables)
    }
}
