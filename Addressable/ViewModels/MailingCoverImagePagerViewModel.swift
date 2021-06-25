//
//  MailingCoverImagePagerViewModel.swift
//  Addressable
//
//  Created by Ari on 6/17/21.
//

import SwiftUI
import Combine


class MailingCoverImagePagerViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    var mailing: Mailing
    var selectedCoverImageId: Int

    @Published var renderedImageType: MailingImages = .envelopeOutside
    @Published var refreshMailingTask = DispatchWorkItem {}

    @Published var envelopeOutsideImageData: Data?
    @Published var cardFrontImageData: Data?
    @Published var cardInsideImageData: Data?
    @Published var cardBackImageData: Data?

    @Binding var selectedFrontCoverImageData: Data?
    @Binding var selectedBackCoverImageData: Data?

    init(
        provider: DependencyProviding,
        selectedMailing: Mailing,
        selectedFrontImageData: Binding<Data?>,
        selectedBackImageData: Binding<Data?>,
        selecteImageId: Int
    ) {
        apiService = provider.register(provider: provider)
        mailing = selectedMailing
        selectedCoverImageId = selecteImageId

        _selectedFrontCoverImageData = selectedFrontImageData
        _selectedBackCoverImageData = selectedBackImageData

        refreshMailingTask = DispatchWorkItem {
            self.refreshMailing()
        }
    }

    func getMailingImages() {
        for mailingImageType in MailingImages.allCases {
            switch mailingImageType {
            case .envelopeOutside:
                getImageData(for: .envelopeOutside, with: mailing.envelopeOutsidePreviewUrl)
            case .cardFront:
                getImageData(for: .cardFront, with: mailing.previewCardFrontUrl)
            case .cardInside:
                getImageData(for: .cardInside, with: mailing.cardInsidePreviewUrl)
            case .cardBack:
                getImageData(for: .cardBack, with: mailing.previewCardBackUrl)
            }
        }
    }

    private func getImageData(for image: MailingImages, with imageUrl: String?) {
        guard let urlString = imageUrl,
              let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                switch image {
                case .envelopeOutside:
                    self.envelopeOutsideImageData = data
                case .cardFront:
                    self.cardFrontImageData = data
                case .cardInside:
                    self.cardInsideImageData = data
                case .cardBack:
                    self.cardBackImageData = data
                }
            }
        }
        task.resume()
    }

    func refreshMailing() {
        apiService.getSelectedRadiusMailing(for: mailing.id)
            .map { $0.radiusMailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("refreshMailing(with id: \(self.mailing.id) receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { mailing in
                    // Recurssively get mailing until illustrator_job_queue is finished building card inside preview image
                    switch self.renderedImageType {
                    case .envelopeOutside:
                        guard let envelopeOutsidePreviewUrl = mailing.envelopeOutsidePreviewUrl else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: self.refreshMailingTask)
                            return
                        }
                        self.getImageData(for: self.renderedImageType, with: envelopeOutsidePreviewUrl)
                    case .cardFront:
                        guard let previewCardFrontUrl = mailing.previewCardFrontUrl else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: self.refreshMailingTask)
                            return
                        }
                        self.getImageData(for: self.renderedImageType, with: previewCardFrontUrl)
                    case .cardInside:
                        guard let cardInsidePreviewUrl = mailing.cardInsidePreviewUrl else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: self.refreshMailingTask)
                            return
                        }
                        self.getImageData(for: self.renderedImageType, with: cardInsidePreviewUrl)
                    case .cardBack:
                        guard let previewCardBackUrl = mailing.previewCardBackUrl else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: self.refreshMailingTask)
                            return
                        }
                        self.getImageData(for: self.renderedImageType, with: previewCardBackUrl)
                    }
                })
            .store(in: &disposables)
    }
}
