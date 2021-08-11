//
//  SelectAudienceViewModel.swift
//  Addressable
//
//  Created by Ari on 8/9/21.
//

import SwiftUI
import Combine

class SelectAudienceViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    @Binding var mailing: Mailing

    @Published var audiences: [ListUpload] = []
    @Published var loadingAudiences: Bool = false

    init(provider: DependencyProviding, selectedMailing: Binding<Mailing>) {
        apiService = provider.register(provider: provider)
        _mailing = selectedMailing
    }

    func getAudiences() {
        loadingAudiences = true
        apiService.getListUploads()
            .map { listUploadWrapper in listUploadWrapper.listUploads.map { $0.listUpload } }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard self != nil else { return }
                    switch value {
                    case .failure(let error):
                        guard let self = self else { return }
                        print("getListUploads() receiveCompletion error: \(error)")
                        self.loadingAudiences = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] listUploads in
                    guard let self = self else { return }
                    self.audiences = listUploads
                    self.loadingAudiences = false
                })
            .store(in: &disposables)
    }

    func addAudience(
        with audienceId: Int,
        completion: @escaping (Mailing?) -> Void
    ) {
        guard let addAudienceData = try? JSONEncoder().encode(
            AddAudienceToMailingWrapper(mailing: AddAudience(audienceIds: [audienceId]))
        ) else {
            print("Add Audience Encoding Error")
            return
        }

        apiService.updateMailingListUpload(for: mailing.id, addAudienceData)
            .map { resp in
                resp.mailing
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {[weak self]value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("updateMailingListUpload(mailingId: \(self.mailing.id)," +
                                " receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { mailingWithAudience in
                    completion(mailingWithAudience)
                })
            .store(in: &disposables)
    }
}
