//
//  TagIncomingLeadViewModel.swift
//  Addressable
//
//  CreIated by Ari on 3/4/21.
//

import SwiftUI
import Combine

class TagIncomingLeadViewModel: ObservableObject {
    @Published var caller: String = ""
    @Published var isRealOrSpamSelectedTag: IncomingLeadTagOptions = .person
    @Published var isInterestedSelectedTag: IncomingLeadTagOptions = .lowInterest
    @Published var isRemovalSelectedTag: IncomingLeadTagOptions = .removeNo
    @Published var userNotes: String = ""
    @Published var leadNotes: [UserNote] = []

    @Binding var subjectLead: IncomingLead?

    private let apiService: ApiService
    let analyticsTracker: AnalyticsTracker
    private var disposables = Set<AnyCancellable>()

    init(provider: DependencyProviding, lead: Binding<IncomingLead?>) {
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
        _subjectLead = lead

        if let selectedlead = subjectLead {
            switch selectedlead.qualityScore {
            case 1:
                isInterestedSelectedTag = .lowInterest
            case 2:
                isInterestedSelectedTag = .fair
            case 3:
                isInterestedSelectedTag = .lead
            default:
                break
            }
            isRealOrSpamSelectedTag = selectedlead.status == "spam" ? .spam : .person
            isRemovalSelectedTag = selectedlead.status == "removed" ? .removeYes : .removeNo
            leadNotes = selectedlead.userNotes
        }
    }

    func tagIncomingLead(for leadID: Int, completion: @escaping (IncomingLead?) -> Void) {
        guard let tagData = try? JSONEncoder().encode(
            TagIncomingLeadWrapper(incomingLead:
                                    IncomingLeadTag(
                                        spam: isRealOrSpamSelectedTag == .spam ? "true" : "false",
                                        qualityScore: getQualityScore(),
                                        removal: isRemovalSelectedTag == .removeYes ? "1" : "0"))
        ) else {
            print("Encoding Error in tagIncomingLead()")
            return
        }

        apiService.tagIncomingLead(with: leadID, tagData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("tagIncomingLead(for leadID: \(leadID) receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { taggedLead in
                    completion(taggedLead.incomingLead)
                })
            .store(in: &disposables)
    }

    private func getQualityScore() -> Int {
        switch isInterestedSelectedTag {
        case .lowInterest:
            return 1
        case .fair:
            return 2
        case .lead:
            return 3
        default:
            return 0
        }
    }

    func saveUserNote(completion: @escaping (IncomingLead?) -> Void) {
        if let lead = subjectLead {
            guard !userNotes.isEmpty else {
                print("No Subject Lead or Note to Save Notes")
                return
            }
            guard let noteData = try? JSONEncoder().encode(
                OutgoingUserNote(note: Note(userID: lead.userID, note: userNotes))
            ) else {
                print("Encoding Error in saveUserNote()")
                return
            }

            apiService.addUserNotes(
                accountId: lead.accountID,
                leadId: lead.id,
                noteData
            )
            .map {
                $0.incomingLead
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("saveUserNote(" +
                                "for lead_id: \(lead.id)), " +
                                "receiveCompletion error: \(error)"
                        )
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] updatedIncomingLead in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.leadNotes = updatedIncomingLead.userNotes
                        self.userNotes = ""
                    }
                    completion(updatedIncomingLead)
                })
            .store(in: &disposables)
        }
    }
}
