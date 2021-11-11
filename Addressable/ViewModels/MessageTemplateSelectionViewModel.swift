//
//  MessageTemplateSelectionViewModel.swift
//  Addressable
//
//  Created by Ari on 8/6/21.
//

import SwiftUI
import Combine

class MessageTemplateSelectionViewModel: ObservableObject {
    private let apiService: ApiService
    let analyticsTracker: AnalyticsTracker
    private var disposables = Set<AnyCancellable>()

    @Binding var mailing: Mailing

    @Published var loadingMessageTemplates: Bool = false
    @Published var selectedMessageTemplateID: Int = 0
    @Published var messageTemplates: [MessageTemplate] = []
    @Published var messageTemplateMergeVariables: [String: String] = [:]
    @Published var messageTemplateBody: String = ""

    init(provider: DependencyProviding, selectedMailing: Binding<Mailing>) {
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
        _mailing = selectedMailing
    }

    func getMessageTemplates() {
        loadingMessageTemplates = true
        apiService.getMessageTemplates(for: mailing.id)
            .map { resp in resp.messageTemplates.map { $0.messageTemplate } }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMessageTemplates() receiveCompletion error: \(error)")
                        self.messageTemplates = []
                        self.selectedMessageTemplateID = 0
                        self.messageTemplateMergeVariables = [:]
                        self.loadingMessageTemplates = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] messageTemplates in
                    guard let self = self else { return }
                    guard !messageTemplates.isEmpty else {
                        self.messageTemplates = []
                        self.selectedMessageTemplateID = 0
                        self.messageTemplateMergeVariables = [:]
                        self.loadingMessageTemplates = false
                        return
                    }
                    self.messageTemplates = messageTemplates
                    // Initialize view with selected template if it exsists
                    if let selectedMailingMessageTemplateId = self.mailing.customNoteTemplateID,
                       let selectedMessageTemplate = self.messageTemplates.first(
                        where: { $0.id == selectedMailingMessageTemplateId }
                       ) {
                        self.selectedMessageTemplateID = selectedMessageTemplate.id
                        self.messageTemplateMergeVariables = selectedMessageTemplate.mergeVars.mapValues { $0 ?? "" }
                    }
                    self.loadingMessageTemplates = false
                })
            .store(in: &disposables)
    }

    func updateMessageTemplate(
        with messageTemplateId: Int,
        completion: @escaping (MessageTemplate?) -> Void
    ) {
        guard let encodedMessageTemplateData = try? JSONEncoder().encode(
            OutgoingMessageTemplateWrapper(
                mailingId: mailing.id,
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
                        print("updateMessageTemplate(templateBody: \(self.messageTemplateBody)," +
                                " receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] updatedMessageTemplate in
                    guard let self = self else { return }
                    if let oldTemplateIndex = self.messageTemplates.firstIndex(
                        where: { $0.id == updatedMessageTemplate.id }
                    ) {
                        self.messageTemplates[oldTemplateIndex] = updatedMessageTemplate
                    }
                    completion(updatedMessageTemplate)
                })
            .store(in: &disposables)
    }

    func addMessageTemplate(
        _ messageTemplate: MessageTemplate,
        completion: @escaping (Mailing?) -> Void
    ) {
        guard let addMessageTemplateData = try? JSONEncoder().encode(
            UpdateMailingMessageTemplate(
                customNote: AddMessageTemplate(
                    messageTemplateId: messageTemplate.id,
                    customNoteBody: messageTemplate.body,
                    mergeVars: messageTemplateMergeVariables)
            )
        ) else {
            print("Add Message Template Encoding Error")
            return
        }

        apiService.updateMailingMessageTemplate(
            for: mailing.id,
            addMessageTemplateData
        )
        .map { resp in
            resp.mailing
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: {[weak self]value in
                guard let self = self else { return }
                switch value {
                case .failure(let error):
                    print("updateMailingMessageTemplate(mailingId: \(self.mailing.id)," +
                            " receiveCompletion error: \(error)")
                    completion(nil)
                case .finished:
                    break
                }
            },
            receiveValue: { mailingWithMessageTemplate in
                completion(mailingWithMessageTemplate)
            })
        .store(in: &disposables)
    }
}
