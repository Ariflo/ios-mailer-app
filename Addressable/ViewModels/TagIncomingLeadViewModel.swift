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

    @Binding var subjectLead: IncomingLead?

    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    init(provider: DependencyProviding, lead: Binding<IncomingLead?>) {
        apiService = provider.register(provider: provider)
        _subjectLead = lead
        // swiftlint:disable force_unwrapping
        if subjectLead != nil {
            switch subjectLead!.qualityScore {
            case 1:
                isInterestedSelectedTag = .lowInterest
            case 2:
                isInterestedSelectedTag = .fair
            default:
                isInterestedSelectedTag = .lead
            }
            isRealOrSpamSelectedTag = subjectLead!.status == "spam" ? .spam : .person
            isRemovalSelectedTag = subjectLead!.status == "removed" ? .removeYes : .removeNo
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
}
