//
//  TagIncomingLeadViewModel.swift
//  Addressable
//
//  CreIated by Ari on 3/4/21.
//

import SwiftUI
import Combine

class TagIncomingLeadViewModel: ObservableObject, Identifiable {
    @Published var caller: String = ""
    @Published var isRealOrSpamSelectedTag: IncomingLeadTagOptions = .person
    @Published var isInterestedSelectedTag: IncomingLeadTagOptions = .lowInterest
    @Published var isRemovalSelectedTag: IncomingLeadTagOptions = .removeNo

    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
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

        addressableDataFetcher.tagIncomingLead(with: leadID, tagData)
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
