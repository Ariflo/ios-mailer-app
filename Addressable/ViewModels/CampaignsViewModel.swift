//
//  CampaignsViewModel.swift
//  Addressable
//
//  Created by Ari on 5/24/21.
//

import SwiftUI
import Combine
import CoreData

class CampaignsViewModel: ObservableObject {
    @Published var loadingMailings: Bool = false
    @Published var loadingLeads: Bool = false
    @Published var loadingLeadsWithMessages: Bool = false
    @Published var numOfUntaggedLeads: Int = 0
    @Published var numOfCampaigns: Int = 0
    @Published var numOfCards: Int = 0
    @Published var numOfCalls: Int = 0
    @Published var numOfTextMessages: Int = 0

    @Published var refreshMailingData: Bool = false {
        didSet {
            if oldValue == false && refreshMailingData == true {
                getAllMailingCampaigns()
                // When finished refreshing data (must be done on the main thread)
                self.refreshMailingData = false
            }
        }
    }

    private let apiService: ApiService
    let analyticsTracker: AnalyticsTracker
    private var disposables = Set<AnyCancellable>()
    private var context: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext, provider: DependencyProviding) {
        context = managedObjectContext
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
    }

    func getAllMailingCampaigns() {
        loadingMailings = true
        apiService.getCurrentUserMailingCampaigns()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getAllMailingCampaigns() receiveCompletion error: \(error)")
                        self.numOfCampaigns = 0
                        self.loadingMailings = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] campaignsData in
                    guard let self = self,
                          let persistedCampaigns: [PersistedCampaign] = try? self.context.fetch(
                            PersistedCampaign.fetchRequest()
                          ) else { return }
                    if campaignsData.campaigns.isEmpty && !persistedCampaigns.isEmpty {
                        PersistedCampaign.clearAll(using: self.context)
                    }
                    // TODO: Include Audience, Sphere, and the rest when the features are added
                    for mailing in campaignsData.campaigns.compactMap({ $0.mailing }) {
                        guard let encodedMailingData = try? JSONEncoder().encode(mailing) else {
                            print("New Mailing Encoding Error")
                            return
                        }

                        let storedMailings: [Mailing] = persistedCampaigns.compactMap { campaignMailing in
                            try? JSONDecoder().decode(Mailing.self, from: campaignMailing.mailing)
                        }

                        if !storedMailings.contains(mailing) {
                            PersistedCampaign.createWith(
                                mailingData: encodedMailingData,
                                using: self.context
                            )
                        } else {
                            PersistedCampaign.updateStoredMailing(
                                with: mailing.id,
                                mailingData: encodedMailingData,
                                using: self.context
                            )
                        }
                    }
                    self.numOfCampaigns = campaignsData.campaigns.compactMap { $0.mailing }
                        .filter { $0.relatedMailing == nil || $0.relatedMailing?.parentMailingID != nil }.count
                    self.numOfCards = campaignsData.campaigns
                        .compactMap { $0.mailing }
                        .filter { $0.mailingStatus == "mailed" }
                        .reduce(0) { total, mailing in total + mailing.activeRecipientCount
                        }
                    self.loadingMailings = false
                })
            .store(in: &disposables)
    }

    func getLeads() {
        loadingLeads = true
        apiService.getIncomingLeads()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getLeads() receiveCompletion error: \(error)")
                        self.numOfUntaggedLeads = 0
                        self.numOfCalls = 0
                        self.loadingLeads = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    guard let self = self else { return }
                    self.numOfUntaggedLeads = incomingLeads.filter { $0.status == "unknown" }.count
                    self.numOfCalls = incomingLeads.count
                    self.loadingLeads = false
                })
            .store(in: &disposables)
    }

    func getIncomingLeadsWithMessages() {
        loadingLeadsWithMessages = true
        apiService.getIncomingLeadsWithMessages()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getIncomingLeadsWithMessages() receiveCompletion error: \(error)")
                        self.numOfTextMessages = 0
                        self.loadingLeadsWithMessages = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeadsWithMessages in
                    guard let self = self else { return }
                    for lead in incomingLeadsWithMessages {
                        self.getMessages(for: lead.id)
                    }
                    self.loadingLeadsWithMessages = false
                })
            .store(in: &disposables)
    }

    func getMessages(for leadId: Int) {
        apiService.getLeadMessages(for: leadId)
            .map { $0.leadMessages
                .compactMap { msg -> Message? in
                    do {
                        if let msgData = msg.data(using: .utf8) {
                            return try JSONDecoder().decode(Message.self, from: msgData)
                        } else {
                            return nil
                        }
                    } catch {
                        print("getMessages(for leadID: \(leadId)) JSON decoding error: \(error)")
                        return nil
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("getMessages() receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] messages in
                    guard let self = self else { return }
                    self.numOfTextMessages += messages.filter { $0.isIncoming }.count
                })
            .store(in: &disposables)
    }
}
