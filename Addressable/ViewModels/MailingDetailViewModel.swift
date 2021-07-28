//
//  MailingDetailViewModel.swift
//  Addressable
//
//  Created by Ari on 6/7/21.
//

import SwiftUI
import Combine

class MailingDetailViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    @Published var mailing: Mailing

    @Published var selectedFrontImageData: Data?
    @Published var selectedBackImageData: Data?
    @Published var selectedImageId: Int = 0

    init(provider: DependencyProviding, selectedMailing: Mailing) {
        apiService = provider.register(provider: provider)
        mailing = selectedMailing

        if let layoutTemplateId = selectedMailing.layoutTemplate?.id {
            selectedImageId = layoutTemplateId
        }
    }
}
